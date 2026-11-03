"""
app/modules/users/router.py

FastAPI router cho users module.
Endpoints:
  GET    /users/me                 — Lấy profile đầy đủ
  PATCH  /users/me                 — Cập nhật display_name, avatar_url
  POST   /users/me/fcm-token       — Đăng ký FCM device token
  DELETE /users/me/fcm-token       — Xóa FCM token khi đăng xuất
  DELETE /users/me                 — Yêu cầu xóa tài khoản (soft-delete)
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User

from .schemas import (
    DeleteAccountRequest,
    ProfileResponse,
    UpdateFcmTokenRequest,
    UpdateProfileRequest,
)
from .service import UsersService

router = APIRouter(prefix="/users", tags=["users"])


# ── Dependency ────────────────────────────────────────────────────────────────

def get_users_service(db: AsyncSession = Depends(get_db)) -> UsersService:
    return UsersService(db=db)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/me",
    response_model=ProfileResponse,
    summary="Lấy hồ sơ đầy đủ của user hiện tại",
)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
) -> ProfileResponse:
    """Trả toàn bộ thông tin hồ sơ, bao gồm XP, streak và trạng thái AI."""
    return ProfileResponse.model_validate(current_user)


@router.patch(
    "/me",
    response_model=ProfileResponse,
    summary="Cập nhật hồ sơ cá nhân",
)
async def update_my_profile(
    body: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    service: UsersService = Depends(get_users_service),
) -> ProfileResponse:
    """
    Cập nhật display_name và/hoặc avatar_url.
    Chỉ các trường có trong body mới được cập nhật (partial update).
    """
    updated = await service.update_profile(
        user=current_user,
        display_name=body.display_name,
        avatar_url=body.avatar_url,
    )
    return ProfileResponse.model_validate(updated)


@router.post(
    "/me/fcm-token",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Đăng ký FCM device token để nhận thông báo học tập",
)
async def register_fcm_token(
    body: UpdateFcmTokenRequest,
    current_user: User = Depends(get_current_user),
    service: UsersService = Depends(get_users_service),
) -> None:
    """Lưu FCM token của thiết bị hiện tại. Gọi khi app khởi động hoặc token được refresh."""
    await service.update_fcm_token(user=current_user, fcm_token=body.fcm_token)


@router.delete(
    "/me/fcm-token",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Xóa FCM token khi đăng xuất",
)
async def remove_fcm_token(
    current_user: User = Depends(get_current_user),
    service: UsersService = Depends(get_users_service),
) -> None:
    """Xóa FCM token khỏi DB khi user đăng xuất để ngừng nhận push notification."""
    await service.clear_fcm_token(user=current_user)


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Yêu cầu xóa tài khoản",
)
async def delete_my_account(
    body: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    service: UsersService = Depends(get_users_service),
) -> None:
    """
    Soft-delete tài khoản: đánh dấu is_active=False, xóa credentials nhạy cảm.
    Yêu cầu gửi kèm `confirmation = 'DELETE_MY_ACCOUNT'` để tránh vô tình xóa.
    """
    if body.confirmation != "DELETE_MY_ACCOUNT":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "INVALID_CONFIRMATION",
                "message": "Confirmation string không đúng. Gửi 'DELETE_MY_ACCOUNT'.",
            },
        )
    await service.deactivate_account(user=current_user)
