"""
app/modules/vocab/schemas.py

Pydantic schemas cho vocab module.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class WordResponse(BaseModel):
    """Một từ trong word catalog."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    lemma: str
    ipa: str
    pos: str
    meaning_vi: str
    example_en: str
    example_vi: str
    topic: str
    image_url: str | None
    is_seeded: bool
    is_ai_generated: bool
    created_at: datetime


class WordListResponse(BaseModel):
    """Paginated list of words."""

    items: list[WordResponse]
    total: int
    page: int
    page_size: int
    has_next: bool
