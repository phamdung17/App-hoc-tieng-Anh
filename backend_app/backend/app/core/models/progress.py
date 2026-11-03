"""
app/core/models/progress.py

Model theo dõi hoạt động học tập hàng ngày của người dùng.
"""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, Integer, UniqueConstraint, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

from .base import TimestampMixin


class UserDailyActivity(TimestampMixin, Base):
    """Ghi nhận hoạt động học tập của user theo từng ngày."""

    __tablename__ = "user_daily_activities"

    __table_args__ = (
        UniqueConstraint("user_id", "activity_date", name="uq_user_daily_activities_user_date"),
    )

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Foreign Key ───────────────────────────────────────────────────────
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # ── Activity Data ─────────────────────────────────────────────────────
    activity_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    xp_earned: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
        server_default="0",
        comment="XP kiếm được trong ngày này.",
    )

    lessons_completed: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
        server_default="0",
        comment="Số bài hoàn thành trong ngày.",
    )

    minutes_studied: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
        server_default="0",
        comment="Số phút học ước tính trong ngày.",
    )

    def __repr__(self) -> str:
        return (
            f"<UserDailyActivity user_id={self.user_id} "
            f"date={self.activity_date} xp={self.xp_earned}>"
        )
