"""
app/modules/auth/router.py

FastAPI router cho auth module.
Endpoints:
  POST /auth/register       — Tạo tài khoản mới
  POST /auth/login          — Đăng nhập, nhận token pair
  POST /auth/social/google  — Đăng nhập bằng Google OAuth ID token
  POST /auth/refresh        — Làm mới access token
  GET  /auth/me             — Thông tin user hiện tại
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User

from .errors import (
    EmailAlreadyRegisteredError,
    InvalidCredentialsError,
    InvalidResetTokenError,
    UserNotFoundError,
)
from .schemas import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    MessageResponse,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    SocialGoogleRequest,
    TokenResponse,
    UserResponse,
)
from .service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Dependency ────────────────────────────────────────────────────────────────

def get_auth_service(db: AsyncSession = Depends(get_db)) -> AuthService:
    return AuthService(db=db)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký tài khoản mới",
)
async def register(
    body: RegisterRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    """
    Tạo tài khoản mới, trả token pair để FE sử dụng ngay.
    """
    try:
        return await service.register(
            email=body.email,
            password=body.password,
            display_name=body.display_name,
        )
    except EmailAlreadyRegisteredError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": exc.code, "message": exc.message},
        ) from exc


@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Đăng nhập",
)
async def login(
    body: LoginRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    """Xác thực credentials, trả access + refresh token."""
    try:
        return await service.login(email=body.email, password=body.password)
    except InvalidCredentialsError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": exc.code, "message": exc.message},
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


@router.post(
    "/social/google",
    response_model=AuthResponse,
    summary="Đăng nhập bằng Google OAuth ID token",
)
async def login_google(
    body: SocialGoogleRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthResponse:
    """Xác minh Google idToken, trả access + refresh token của app."""
    try:
        return await service.login_with_google(body.id_token)
    except InvalidCredentialsError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_GOOGLE_TOKEN", "message": "ID token từ Google không hợp lệ hoặc đã hết hạn."},
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Làm mới access token",
)
async def refresh(
    body: RefreshRequest,
    service: AuthService = Depends(get_auth_service),
) -> TokenResponse:
    """Dùng refresh token để lấy access token mới (token rotation)."""
    try:
        return await service.refresh(body.refresh_token)
    except InvalidCredentialsError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_REFRESH_TOKEN", "message": exc.message},
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    summary="Yêu cầu đặt lại mật khẩu",
)
async def forgot_password(
    body: ForgotPasswordRequest,
    service: AuthService = Depends(get_auth_service),
) -> MessageResponse:
    """Gửi link/token đặt lại mật khẩu qua email."""
    await service.forgot_password(body.email)
    return MessageResponse(
        message="If the email exists, password reset instructions have been sent"
    )


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    summary="Đặt lại mật khẩu bằng reset token",
)
async def reset_password(
    body: ResetPasswordRequest,
    service: AuthService = Depends(get_auth_service),
) -> MessageResponse:
    """Đặt lại mật khẩu mới bằng token hợp lệ."""
    try:
        await service.reset_password(token=body.token, new_password=body.password)
        return MessageResponse(message="Password reset successfully")
    except InvalidResetTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": exc.code, "message": exc.message},
        ) from exc
    except UserNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": exc.code, "message": exc.message},
        ) from exc


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Thông tin user hiện tại",
)
async def get_me(
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Trả thông tin profile của user đang đăng nhập."""
    return UserResponse.model_validate(current_user)
