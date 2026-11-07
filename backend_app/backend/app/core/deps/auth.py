"""
app/core/deps/auth.py

FastAPI dependencies cho authentication:
  - get_current_user  : xác thực JWT, trả User object
  - require_ai_user   : get_current_user + kiểm tra email verified

Dùng OAuth2 Bearer token từ header Authorization.
"""

from __future__ import annotations

import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.models.user import User
from app.core.security.jwt import (
    TokenExpiredError,
    TokenInvalidError,
    decode_access_token,
)

# OAuth2 scheme — FastAPI sẽ đọc Bearer token từ Authorization header
# tokenUrl trỏ đến endpoint login để Swagger UI hoạt động
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# ── Dependencies ──────────────────────────────────────────────────────────────

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Dependency: xác thực JWT access token, trả User từ DB.

    Raises:
        401 UNAUTHORIZED: Token hết hạn, invalid, hoặc user không tồn tại.
    """
    # Decode token → user_id
    try:
        user_id = decode_access_token(token)
    except TokenExpiredError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "TOKEN_EXPIRED", "message": "Access token has expired"},
            headers={"WWW-Authenticate": "Bearer"},
        )
    except TokenInvalidError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_TOKEN", "message": "Invalid access token"},
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Tra DB lấy user
    stmt = select(User).where(User.id == user_id, User.is_active == True)  # noqa: E712
    user = (await db.execute(stmt)).scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "USER_NOT_FOUND", "message": "User not found or inactive"},
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


async def require_ai_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """
    Dependency: get_current_user cho tất cả AI endpoints (scan, v.v.).
    Không yêu cầu xác minh email.
    """
    return current_user


async def get_optional_user(
    token: str | None = Depends(
        OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)
    ),
    db: AsyncSession = Depends(get_db),
) -> User | None:
    """
    Dependency: trả User nếu có token hợp lệ, None nếu không có.
    Dùng cho các endpoint public nhưng vẫn muốn biết user là ai.
    """
    if token is None:
        return None
    try:
        user_id = decode_access_token(token)
        stmt = select(User).where(User.id == user_id, User.is_active == True)  # noqa: E712
        return (await db.execute(stmt)).scalar_one_or_none()
    except (TokenExpiredError, TokenInvalidError):
        return None
