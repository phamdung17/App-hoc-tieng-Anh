"""
app/modules/vocab/schemas.py

Pydantic schemas cho vocab module.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


# ── Word card response ────────────────────────────────────────────────────────

class WordResponse(BaseModel):
    """Thẻ từ đầy đủ — trả trong list và detail."""
    id: uuid.UUID
    lemma: str
    ipa: str
    pos: str
    meaning_vi: str
    example_en: str
    example_vi: str
    topic: str
    image_url: Optional[str] = None
    is_seeded: bool
    is_ai_generated: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class WordListResponse(BaseModel):
    """Kết quả phân trang danh sách từ."""
    items: list[WordResponse]
    total: int
    page: int
    page_size: int
    has_next: bool

