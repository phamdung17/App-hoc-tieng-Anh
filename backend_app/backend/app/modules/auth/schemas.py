"""
app/modules/auth/schemas.py

Pydantic schemas cho auth API endpoints.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator


# ── Requests ─────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    """POST /auth/register"""
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    display_name: str = Field(min_length=1, max_length=80, default="")

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        """Yêu cầu ít nhất 1 chữ hoa, 1 chữ thường, 1 số."""
        if not any(c.isupper() for c in v):
            raise ValueError("Password phải có ít nhất 1 chữ hoa")
        if not any(c.islower() for c in v):
            raise ValueError("Password phải có ít nhất 1 chữ thường")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password phải có ít nhất 1 chữ số")
        return v


class LoginRequest(BaseModel):
    """POST /auth/login"""
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    """POST /auth/refresh"""
    refresh_token: str


class VerifyEmailRequest(BaseModel):
    """POST /auth/verify-email"""
    token: str


class ResendVerifyRequest(BaseModel):
    """POST /auth/resend-verify"""
    email: EmailStr


# ── Responses ─────────────────────────────────────────────────────────────────

class TokenResponse(BaseModel):
    """Access + refresh token pair."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int             # seconds đến access token hết hạn


class UserResponse(BaseModel):
    """Thông tin cơ bản của user — trả sau register/login."""
    id: uuid.UUID
    email: str
    display_name: str
    email_verified: bool
    is_guest: bool
    xp_total: int
    streak_days: int
    created_at: datetime

    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    """Response đầy đủ sau login/register: token + user info."""
    tokens: TokenResponse
    user: UserResponse


class MessageResponse(BaseModel):
    """Generic message response."""
    message: str
