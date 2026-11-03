"""
app/modules/users/schemas.py

Pydantic schemas cho users module.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, HttpUrl


# ── Requests ─────────────────────────────────────────────────────────────────

class UpdateProfileRequest(BaseModel):
    """PATCH /users/me — chỉ cập nhật các trường được gửi lên."""
    display_name: Optional[str] = Field(None, min_length=1, max_length=80)
    avatar_url: Optional[str] = Field(None, max_length=500)


class UpdateFcmTokenRequest(BaseModel):
    """POST /users/me/fcm-token"""
    fcm_token: str = Field(min_length=10, max_length=500)


class DeleteAccountRequest(BaseModel):
    """DELETE /users/me — xác nhận xóa tài khoản."""
    confirmation: str = Field(description="Phải bằng 'DELETE_MY_ACCOUNT'")


# ── Responses ─────────────────────────────────────────────────────────────────

class ProfileResponse(BaseModel):
    """Hồ sơ đầy đủ của user hiện tại."""
    id: uuid.UUID
    email: str
    display_name: str
    avatar_url: Optional[str]
    email_verified: bool
    is_guest: bool
    # Gamification
    xp_total: int
    streak_days: int
    last_activity_date: Optional[datetime]
    # AI
    ai_scan_count_total: int
    # Meta
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
