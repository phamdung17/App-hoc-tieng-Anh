"""
app/modules/users/router.py

FastAPI router cho users module.
Endpoints:
  - GET  /users/me         : profile của chính mình
  - PATCH /users/me        : cập nhật display_name, avatar_url
  - PUT  /users/me/fcm     : update FCM token thiết bị
  - DELETE /users/me       : xóa tài khoản (soft delete)
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User

from .schemas import UpdateFcmTokenRequest, UpdateProfileRequest, UserProfileResponse

router = APIRouter(prefix="/users", tags=["users"])


# ── GET /users/me ─────────────────────────────────────────────────────────────

@router.get(
    "/me",
    response_model=UserProfileResponse,
    summary="Lấy profile của chính mình",
)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
) -> UserProfileResponse:
    """Trả về thông tin profile của user đang đăng nhập."""
    return UserProfileResponse.model_validate(current_user)


# ── PATCH /users/me ───────────────────────────────────────────────────────────

@router.patch(
    "/me",
    response_model=UserProfileResponse,
    summary="Cập nhật profile",
)
async def update_my_profile(
    body: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserProfileResponse:
    """
    Cập nhật display_name và/hoặc avatar_url.
    Chỉ cập nhật các trường được gửi lên (partial update).
    """
    if body.display_name is not None:
        if len(body.display_name) < 1 or len(body.display_name) > 80:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={
                    "code": "INVALID_DISPLAY_NAME",
                    "message": "Display name phải từ 1 đến 80 ký tự.",
                },
            )
        current_user.display_name = body.display_name

    if body.avatar_url is not None:
        current_user.avatar_url = body.avatar_url

    # commit sẽ được gọi bởi get_db() sau khi return
    return UserProfileResponse.model_validate(current_user)


# ── PUT /users/me/fcm ─────────────────────────────────────────────────────────

@router.put(
    "/me/fcm",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Cập nhật FCM token thiết bị",
)
async def update_fcm_token(
    body: UpdateFcmTokenRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """
    Lưu FCM token của thiết bị hiện tại.
    Gọi mỗi khi app mở và FCM token thay đổi.
    """
    current_user.fcm_token = body.fcm_token


# ── DELETE /users/me ──────────────────────────────────────────────────────────

@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Xóa tài khoản",
)
async def delete_my_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """
    Soft delete: đánh dấu is_active=False, xóa dữ liệu nhạy cảm.
    Ảnh scan được xóa qua ARQ worker (async).
    """
    current_user.is_active = False
    current_user.email = f"deleted_{current_user.id}@deleted"
    current_user.hashed_password = ""
    current_user.fcm_token = None
    current_user.email_verify_token = None
