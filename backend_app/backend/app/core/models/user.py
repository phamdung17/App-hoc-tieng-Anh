"""
app/core/models/user.py

User model — tài khoản người dùng.
Không chứa password plain text; chỉ lưu hashed_password.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Integer, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

from .base import TimestampMixin


class User(TimestampMixin, Base):
    """Tài khoản người dùng."""

    __tablename__ = "users"

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Identity ──────────────────────────────────────────────────────────
    email: Mapped[str] = mapped_column(
        String(254), unique=True, nullable=False, index=True
    )
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    display_name: Mapped[str] = mapped_column(String(80), nullable=False, default="")
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # ── Verification ──────────────────────────────────────────────────────
    email_verified: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    email_verify_token: Mapped[str | None] = mapped_column(String(255), nullable=True)
    email_verify_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # ── AI Usage ─────────────────────────────────────────────────────────
    # Quota tracking được làm chủ bởi Redis (key: scan_quota:{user_id}:{date})
    # Trường này dùng cho reporting/admin, không phải enforcement chính
    ai_scan_count_total: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # ── Gamification ──────────────────────────────────────────────────────
    xp_total: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    streak_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_activity_date: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # ── Status ────────────────────────────────────────────────────────────
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_guest: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # ── FCM ───────────────────────────────────────────────────────────────
    fcm_token: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # ── Relationships ─────────────────────────────────────────────────────
    scans: Mapped[list["Scan"]] = relationship(  # noqa: F821
        "Scan", back_populates="user", lazy="noload"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r}>"
