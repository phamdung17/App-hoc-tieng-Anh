"""
app/modules/auth/service.py

Business logic cho auth module:
  - register: tạo user mới, gửi email verify
  - login: xác thực credentials, trả token pair
  - login_with_google: xác thực Google OAuth idToken
  - refresh: đổi refresh token lấy access token mới
  - verify_email: xác minh email bằng token
  - resend_verify: gửi lại email verify
"""

from __future__ import annotations

import logging
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.models.user import User
from app.core.security.jwt import (
    TokenExpiredError,
    TokenInvalidError,
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
)
from app.core.security.password import hash_password, verify_password

from .errors import (
    EmailAlreadyRegisteredError,
    EmailAlreadyVerifiedError,
    InvalidCredentialsError,
    InvalidVerifyTokenError,
    UserNotFoundError,
)
from .schemas import AuthResponse, TokenResponse, UserResponse

logger = logging.getLogger(__name__)

# TTL cho email verify token
_VERIFY_TOKEN_TTL_HOURS = 24


class AuthService:
    """Service xử lý toàn bộ nghiệp vụ authentication."""

    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    # ── Register ──────────────────────────────────────────────────────────

    async def register(
        self,
        email: str,
        password: str,
        display_name: str = "",
    ) -> AuthResponse:
        """
        Tạo tài khoản mới.

        Raises:
            EmailAlreadyRegisteredError: Email đã tồn tại.
        """
        existing = await self._get_user_by_email(email)
        if existing:
            raise EmailAlreadyRegisteredError()

        verify_token = secrets.token_urlsafe(32)
        verify_expires = datetime.now(timezone.utc) + timedelta(hours=_VERIFY_TOKEN_TTL_HOURS)

        user = User(
            email=email.lower().strip(),
            hashed_password=hash_password(password),
            display_name=display_name.strip() or email.split("@")[0],
            email_verified=False,
            email_verify_token=verify_token,
            email_verify_expires_at=verify_expires,
        )
        self._db.add(user)

        try:
            await self._db.flush()
        except IntegrityError:
            await self._db.rollback()
            raise EmailAlreadyRegisteredError()

        logger.info("New user registered: email=%s id=%s", email, user.id)
        logger.debug("Email verify token for %s: %s", email, verify_token)
        return self._build_auth_response(user)

    # ── Login ─────────────────────────────────────────────────────────────

    async def login(self, email: str, password: str) -> AuthResponse:
        """
        Xác thực credentials, trả token pair.

        Raises:
            InvalidCredentialsError: Email không tồn tại hoặc password sai.
        """
        user = await self._get_user_by_email(email)

        if user is None:
            verify_password("dummy", hash_password("dummy"))
            raise InvalidCredentialsError()

        if not verify_password(password, user.hashed_password):
            raise InvalidCredentialsError()

        if not user.is_active:
            raise InvalidCredentialsError()

        logger.info("User logged in: email=%s id=%s", email, user.id)
        return self._build_auth_response(user)

    # ── Google OAuth ──────────────────────────────────────────────────────

    async def login_with_google(self, id_token: str) -> AuthResponse:
        """
        Xác thực Google ID Token và đăng nhập / tạo user mới.
        """
        import httpx

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(
                    "https://oauth2.googleapis.com/tokeninfo",
                    params={"id_token": id_token},
                )
                if resp.status_code != 200:
                    raise InvalidCredentialsError()
                data = resp.json()
        except httpx.HTTPError as exc:
            logger.warning("Google tokeninfo request failed: %s", exc)
            raise InvalidCredentialsError() from exc

        email = data.get("email")
        if not email:
            raise InvalidCredentialsError()

        user = await self._get_user_by_email(email)
        if user is None:
            display_name = data.get("name") or email.split("@")[0]
            avatar_url = data.get("picture")
            user = User(
                email=email.lower().strip(),
                hashed_password="",
                display_name=display_name,
                avatar_url=avatar_url,
                email_verified=bool(data.get("email_verified", True)),
                is_guest=False,
            )
            self._db.add(user)
            await self._db.commit()
            await self._db.refresh(user)
            logger.info("Created new user via Google Sign-In: id=%s email=%s", user.id, email)
        else:
            if not user.email_verified and data.get("email_verified"):
                user.email_verified = True
                await self._db.commit()
            logger.info("Logged in existing user via Google Sign-In: id=%s", user.id)

        return self._build_auth_response(user)

    # ── Refresh token ─────────────────────────────────────────────────────

    async def refresh(self, refresh_token: str) -> TokenResponse:
        """
        Đổi refresh token → access token mới + refresh token mới.

        Raises:
            InvalidCredentialsError: Token invalid hoặc user không tồn tại.
        """
        try:
            user_id = decode_refresh_token(refresh_token)
        except (TokenExpiredError, TokenInvalidError) as exc:
            raise InvalidCredentialsError() from exc

        user = await self._get_user_by_id(user_id)
        if user is None or not user.is_active:
            raise InvalidCredentialsError()

        return TokenResponse(
            access_token=create_access_token(user.id),
            refresh_token=create_refresh_token(user.id),
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

    # ── Email verification ────────────────────────────────────────────────

    async def verify_email(self, token: str) -> None:
        """
        Xác minh email bằng verify token.

        Raises:
            InvalidVerifyTokenError: Token không hợp lệ hoặc hết hạn.
            EmailAlreadyVerifiedError: Email đã được xác minh.
        """
        stmt = select(User).where(User.email_verify_token == token)
        user = (await self._db.execute(stmt)).scalar_one_or_none()

        if user is None:
            raise InvalidVerifyTokenError()

        if user.email_verified:
            raise EmailAlreadyVerifiedError()

        now = datetime.now(timezone.utc)
        if user.email_verify_expires_at and user.email_verify_expires_at < now:
            raise InvalidVerifyTokenError()

        user.email_verified = True
        user.email_verify_token = None
        user.email_verify_expires_at = None
        logger.info("Email verified: user_id=%s", user.id)

    async def resend_verify(self, email: str) -> None:
        """
        Gửi lại email verify (tạo token mới).

        Raises:
            UserNotFoundError: Email không tồn tại.
            EmailAlreadyVerifiedError: Đã xác minh rồi.
        """
        user = await self._get_user_by_email(email)
        if user is None:
            raise UserNotFoundError()

        if user.email_verified:
            raise EmailAlreadyVerifiedError()

        user.email_verify_token = secrets.token_urlsafe(32)
        user.email_verify_expires_at = datetime.now(timezone.utc) + timedelta(
            hours=_VERIFY_TOKEN_TTL_HOURS
        )
        logger.debug(
            "Resend verify token for %s: %s", email, user.email_verify_token
        )

    # ── Private helpers ───────────────────────────────────────────────────

    async def _get_user_by_email(self, email: str) -> User | None:
        stmt = select(User).where(User.email == email.lower().strip())
        return (await self._db.execute(stmt)).scalar_one_or_none()

    async def _get_user_by_id(self, user_id: uuid.UUID) -> User | None:
        stmt = select(User).where(User.id == user_id)
        return (await self._db.execute(stmt)).scalar_one_or_none()

    def _build_auth_response(self, user: User) -> AuthResponse:
        return AuthResponse(
            tokens=TokenResponse(
                access_token=create_access_token(user.id),
                refresh_token=create_refresh_token(user.id),
                expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            ),
            user=UserResponse.model_validate(user),
        )
