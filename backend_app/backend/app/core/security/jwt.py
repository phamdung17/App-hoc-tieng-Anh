"""
app/core/security/jwt.py

Tạo và xác thực JWT access / refresh tokens.
- Access token: short-lived (15 phút), dùng để gọi API
- Refresh token: long-lived (30 ngày), dùng để lấy access token mới

Payload chuẩn:
    sub   : UUID user (string)
    type  : "access" | "refresh"
    iat   : issued at (Unix timestamp)
    exp   : expiry (Unix timestamp)
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import Literal

from jose import JWTError, jwt

from app.core.config import settings


# ── Token creation ────────────────────────────────────────────────────────────

def create_access_token(user_id: uuid.UUID) -> str:
    """Tạo JWT access token cho user."""
    return _create_token(
        user_id=user_id,
        token_type="access",
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )


def create_refresh_token(user_id: uuid.UUID) -> str:
    """Tạo JWT refresh token cho user."""
    return _create_token(
        user_id=user_id,
        token_type="refresh",
        expires_delta=timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )


def _create_token(
    user_id: uuid.UUID,
    token_type: Literal["access", "refresh"],
    expires_delta: timedelta,
) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


# ── Token verification ────────────────────────────────────────────────────────

class TokenError(Exception):
    """Base class cho lỗi JWT."""
    pass

class TokenExpiredError(TokenError):
    """Token đã hết hạn."""
    pass

class TokenInvalidError(TokenError):
    """Token sai định dạng, signature không khớp, hoặc payload thiếu field."""
    pass


def decode_access_token(token: str) -> uuid.UUID:
    """
    Verify và decode access token.

    Returns:
        UUID của user.

    Raises:
        TokenExpiredError: Token hết hạn.
        TokenInvalidError: Token không hợp lệ.
    """
    return _decode_token(token, expected_type="access")


def decode_refresh_token(token: str) -> uuid.UUID:
    """
    Verify và decode refresh token.

    Returns:
        UUID của user.

    Raises:
        TokenExpiredError: Token hết hạn.
        TokenInvalidError: Token không hợp lệ.
    """
    return _decode_token(token, expected_type="refresh")


def _decode_token(
    token: str, expected_type: Literal["access", "refresh"]
) -> uuid.UUID:
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
    except JWTError as exc:
        # jose raises JWTError cho cả expired và invalid
        if "expired" in str(exc).lower():
            raise TokenExpiredError("Token has expired") from exc
        raise TokenInvalidError(f"Invalid token: {exc}") from exc

    # Kiểm tra type
    if payload.get("type") != expected_type:
        raise TokenInvalidError(
            f"Expected token type '{expected_type}', got '{payload.get('type')}'"
        )

    # Lấy user ID
    sub = payload.get("sub")
    if not sub:
        raise TokenInvalidError("Token missing 'sub' claim")

    try:
        return uuid.UUID(sub)
    except ValueError as exc:
        raise TokenInvalidError(f"Invalid user ID in token: {sub}") from exc
