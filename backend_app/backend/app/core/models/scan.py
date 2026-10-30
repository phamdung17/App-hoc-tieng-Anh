"""
app/core/models/scan.py

Scan và ScanItem models.
Scan = một lần chụp ảnh; ScanItem = một vật thể trong ảnh đó.

Flow (từ scan README):
1. Scan record tạo trước
2. GeminiClient trả DetectedObject list
3. Mỗi DetectedObject → một ScanItem
4. ScanItem.word_id có thể null ban đầu, gắn sau khi tra catalog
"""

from __future__ import annotations

import uuid

from sqlalchemy import (
    Boolean,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

from .base import TimestampMixin


class Scan(TimestampMixin, Base):
    """Một lần scan ảnh của user."""

    __tablename__ = "scans"

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Relationships ─────────────────────────────────────────────────────
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # ── Image ─────────────────────────────────────────────────────────────
    image_key: Mapped[str] = mapped_column(
        String(500), nullable=False,
        comment="Object storage key trong bucket scans-private.",
    )
    image_mime_type: Mapped[str] = mapped_column(
        String(50), nullable=False, default="image/jpeg"
    )

    # ── Status ────────────────────────────────────────────────────────────
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="ok",
        comment="ok | no_object | failed",
    )
    object_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # ── AI metadata ───────────────────────────────────────────────────────
    gemini_model: Mapped[str] = mapped_column(
        String(50), nullable=False, default="",
        comment="Model Gemini đã dùng, ví dụ 'gemini-2.0-flash'.",
    )

    # ── Relationships ─────────────────────────────────────────────────────
    user: Mapped["User"] = relationship(  # noqa: F821
        "User", back_populates="scans", lazy="noload"
    )
    items: Mapped[list["ScanItem"]] = relationship(
        "ScanItem",
        back_populates="scan",
        lazy="noload",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Scan id={self.id} user_id={self.user_id} status={self.status!r}>"


class ScanItem(TimestampMixin, Base):
    """Một vật thể được nhận diện trong một lần scan."""

    __tablename__ = "scan_items"

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Foreign Keys ──────────────────────────────────────────────────────
    scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("scans.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    word_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("words.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
        comment="Null nếu chưa tra được trong catalog hoặc từ mới chưa save.",
    )

    # ── Label ─────────────────────────────────────────────────────────────
    label: Mapped[str] = mapped_column(String(50), nullable=False)
    label_vi: Mapped[str] = mapped_column(String(100), nullable=False, default="")
    confidence: Mapped[float] = mapped_column(Float, nullable=False)

    # ── Word card (snapshot tại thời điểm scan — denormalized) ───────────
    # Lưu riêng để tránh thay đổi retroactively khi Word catalog cập nhật
    ipa: Mapped[str] = mapped_column(String(50), nullable=False, default="")
    pos: Mapped[str] = mapped_column(String(20), nullable=False, default="noun")
    meaning_vi: Mapped[str] = mapped_column(Text, nullable=False, default="")
    example_en: Mapped[str] = mapped_column(Text, nullable=False, default="")
    example_vi: Mapped[str] = mapped_column(Text, nullable=False, default="")
    topic: Mapped[str] = mapped_column(String(50), nullable=False, default="other")

    # ── Bounding Box (x, y, width, height — normalized 0..1) ─────────────
    bbox_x: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    bbox_y: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    bbox_w: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    bbox_h: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)

    # ── Crop image (tạo khi user save từ) ────────────────────────────────
    crop_key: Mapped[str | None] = mapped_column(
        String(500), nullable=True,
        comment="Object storage key cho ảnh crop của vật thể này.",
    )

    # ── User actions ──────────────────────────────────────────────────────
    is_saved: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_reported: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    user_label_override: Mapped[str | None] = mapped_column(
        String(50), nullable=True,
        comment="Label user đổi qua PATCH /scan-items/{id}.",
    )

    # ── Relationships ─────────────────────────────────────────────────────
    scan: Mapped["Scan"] = relationship("Scan", back_populates="items", lazy="noload")
    word: Mapped["Word | None"] = relationship(  # noqa: F821
        "Word", back_populates="scan_items", lazy="noload"
    )

    def __repr__(self) -> str:
        return f"<ScanItem id={self.id} label={self.label!r} conf={self.confidence:.2f}>"
