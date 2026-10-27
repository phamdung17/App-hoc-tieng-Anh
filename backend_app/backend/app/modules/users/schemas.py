"""
app/modules/users/schemas.py

Pydantic schemas cho users module (profile).
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr


class UserProfileResponse(BaseModel):
    """Thông tin public của user — trả cho chính user đó."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    display_name: str
    avatar_url: str | None
    email_verified: bool
    xp_total: int
    streak_days: int
    last_activity_date: datetime | None
    ai_scan_count_total: int
    created_at: datetime


class UpdateProfileRequest(BaseModel):
    """Request body cho PATCH /users/me."""

    display_name: str | None = None
    avatar_url: str | None = None

    model_config = ConfigDict(str_strip_whitespace=True)


class UpdateFcmTokenRequest(BaseModel):
    """Request body để update FCM token thiết bị."""

    fcm_token: str
