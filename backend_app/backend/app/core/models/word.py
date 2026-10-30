"""
app/core/models/word.py

Word model — catalog từ vựng dùng chung.
Vừa là seed data (từ file JSON được biên soạn),
vừa là cache Gemini-generated cards khi scan tìm ra lemma mới.

Quy tắc (từ scan README):
- Nếu Gemini trả lemma đã có → dùng bản đã cache, không ghi đè
- Nếu lemma chưa có → validate Pydantic rồi insert mới vào catalog
"""

from __future__ import annotations

import uuid

from sqlalchemy import Boolean, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

from .base import TimestampMixin


class Word(TimestampMixin, Base):
    """Một từ trong vocabulary catalog."""

    __tablename__ = "words"

    # ── Primary Key ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )

    # ── Core — nhận diện từ ───────────────────────────────────────────────
    lemma: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True,
        comment="Base form của từ (lowercase). Duy nhất trong catalog.",
    )

    # ── Word card — dùng cho học tập ─────────────────────────────────────
    ipa: Mapped[str] = mapped_column(String(50), nullable=False, default="")
    pos: Mapped[str] = mapped_column(
        String(20), nullable=False, default="noun",
        comment="Part of speech: noun, verb, adj, adv, ...",
    )
    meaning_vi: Mapped[str] = mapped_column(
        Text, nullable=False, default="",
        comment="Nghĩa tiếng Việt (definition, không chỉ là dịch từ).",
    )
    example_en: Mapped[str] = mapped_column(Text, nullable=False, default="")
    example_vi: Mapped[str] = mapped_column(Text, nullable=False, default="")
    topic: Mapped[str] = mapped_column(
        String(50), nullable=False, default="other",
        comment="Chủ đề: food, animal, furniture, clothing, ...",
    )

    # ── Media ─────────────────────────────────────────────────────────────
    image_url: Mapped[str | None] = mapped_column(
        String(500), nullable=True,
        comment="Ảnh minh họa từ (public CDN URL, không phải presigned).",
    )

    # ── Nguồn gốc ─────────────────────────────────────────────────────────
    is_seeded: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False,
        comment="True nếu từ này từ seed data đã duyệt.",
    )
    is_ai_generated: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False,
        comment="True nếu card do Gemini tạo và đã được cache.",
    )

    # ── Relationships ─────────────────────────────────────────────────────
    scan_items: Mapped[list["ScanItem"]] = relationship(  # noqa: F821
        "ScanItem", back_populates="word", lazy="noload"
    )

    def __repr__(self) -> str:
        return f"<Word lemma={self.lemma!r} pos={self.pos!r}>"
