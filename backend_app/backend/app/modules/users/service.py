"""
app/modules/users/service.py

Business logic cho users module.
  - Đọc profile
  - Cập nhật display_name, avatar_url
  - Cập nhật FCM token
  - Soft-delete tài khoản (is_active = False)
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.models.user import User


class UsersService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    # ── Profile ──────────────────────────────────────────────────────────────

    async def update_profile(
        self,
        user: User,
        display_name: str | None,
        avatar_url: str | None,
    ) -> User:
        """Cập nhật các trường profile không phải credentials."""
        if display_name is not None:
            user.display_name = display_name.strip()
        if avatar_url is not None:
            user.avatar_url = avatar_url or None   # rỗng → null
        await self._db.commit()
        await self._db.refresh(user)
        return user

    # ── FCM Token ─────────────────────────────────────────────────────────────

    async def update_fcm_token(self, user: User, fcm_token: str) -> None:
        """Lưu FCM device token để gửi push notification."""
        user.fcm_token = fcm_token
        await self._db.commit()

    async def clear_fcm_token(self, user: User) -> None:
        """Xóa FCM token khi user đăng xuất."""
        user.fcm_token = None
        await self._db.commit()

    # ── Account deletion ──────────────────────────────────────────────────────

    async def deactivate_account(self, user: User) -> None:
        """
        Soft-delete: đánh dấu is_active=False, xóa credentials nhạy cảm.
        Không xóa bản ghi để giữ dữ liệu scan history.
        """
        user.is_active = False
        user.email = f"deleted_{user.id}@deleted.invalid"
        user.hashed_password = ""
        user.fcm_token = None
        user.email_verify_token = None
        await self._db.commit()
