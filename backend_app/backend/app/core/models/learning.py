"""
app/core/models/learning.py

Models cho lộ trình học tiếng Anh:
  - LearningPath  → chứa nhiều Unit
  - Unit          → chứa nhiều Lesson
  - Lesson        → nội dung bài học (exercises dưới dạng JSONB)
  - UserLessonProgress → tiến độ của user trên từng Lesson
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

from .base import TimestampMixin


class LearningPath(TimestampMixin, Base):
    """Lộ trình học (VD: Tiếng Anh cơ bản A1)."""

    __tablename__ = "learning_paths"

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Info ──────────────────────────────────────────────────────────────
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    level: Mapped[str] = mapped_column(String(10), nullable=False, default="A1", server_default="A1")
    thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")

    # ── Relationships ─────────────────────────────────────────────────────
    units: Mapped[list["Unit"]] = relationship(
        "Unit", back_populates="path", cascade="all, delete-orphan", lazy="noload"
    )

    def __repr__(self) -> str:
        return f"<LearningPath id={self.id} title={self.title!r} level={self.level!r}>"


class Unit(TimestampMixin, Base):
    """Đơn vị học (chapter) trong một LearningPath."""

    __tablename__ = "units"

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Foreign Key ───────────────────────────────────────────────────────
    path_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("learning_paths.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # ── Info ──────────────────────────────────────────────────────────────
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    order_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    # ── Relationships ─────────────────────────────────────────────────────
    path: Mapped["LearningPath"] = relationship("LearningPath", back_populates="units", lazy="noload")
    lessons: Mapped[list["Lesson"]] = relationship(
        "Lesson", back_populates="unit", cascade="all, delete-orphan", lazy="noload"
    )

    def __repr__(self) -> str:
        return f"<Unit id={self.id} title={self.title!r} order={self.order_index}>"


class Lesson(TimestampMixin, Base):
    """Bài học trong một Unit."""

    __tablename__ = "lessons"

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Foreign Key ───────────────────────────────────────────────────────
    unit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("units.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # ── Info ──────────────────────────────────────────────────────────────
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    lesson_type: Mapped[str] = mapped_column(
        String(20), nullable=False, default="vocabulary", server_default="vocabulary",
        comment="vocabulary | grammar | listening | speaking"
    )
    xp_reward: Mapped[int] = mapped_column(Integer, nullable=False, default=10, server_default="10")
    order_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    # ── Content ───────────────────────────────────────────────────────────
    content_data: Mapped[dict | None] = mapped_column(
        JSONB, nullable=True, comment="Toàn bộ exercises dưới dạng JSON"
    )
    icon_name: Mapped[str | None] = mapped_column(String(50), nullable=True, comment="Tên icon Flutter")

    # ── Relationships ─────────────────────────────────────────────────────
    unit: Mapped["Unit"] = relationship("Unit", back_populates="lessons", lazy="noload")
    progress_records: Mapped[list["UserLessonProgress"]] = relationship(
        "UserLessonProgress", back_populates="lesson", cascade="all, delete-orphan", lazy="noload"
    )

    def __repr__(self) -> str:
        return f"<Lesson id={self.id} title={self.title!r} type={self.lesson_type!r}>"


class UserLessonProgress(TimestampMixin, Base):
    """Tiến độ của một user trên một Lesson cụ thể."""

    __tablename__ = "user_lesson_progress"

    __table_args__ = (
        UniqueConstraint("user_id", "lesson_id", name="uq_user_lesson_progress"),
    )

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Foreign Keys ──────────────────────────────────────────────────────
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    lesson_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("lessons.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # ── Progress ──────────────────────────────────────────────────────────
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="locked", server_default="locked",
        comment="locked | available | completed"
    )
    best_score: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    attempt_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # ── Relationships ─────────────────────────────────────────────────────
    lesson: Mapped["Lesson"] = relationship("Lesson", back_populates="progress_records", lazy="noload")

    def __repr__(self) -> str:
        return f"<UserLessonProgress user={self.user_id} lesson={self.lesson_id} status={self.status!r}>"
