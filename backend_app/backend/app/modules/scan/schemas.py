"""
app/modules/scan/schemas.py

Pydantic schemas cho scan module API.
- Request: multipart upload (UploadFile — handled by FastAPI)
- Response: ScanResponse, ScanItemResponse, QuotaResponse
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class BoundingBoxResponse(BaseModel):
    """Bounding box trả về Flutter (x, y, width, height — normalized 0..1)."""
    x: float = Field(ge=0.0, le=1.0)
    y: float = Field(ge=0.0, le=1.0)
    w: float = Field(ge=0.0, le=1.0)
    h: float = Field(ge=0.0, le=1.0)


class ScanItemResponse(BaseModel):
    """Một vật thể nhận diện được — trả về Flutter."""
    id: uuid.UUID
    label: str
    label_vi: str
    confidence: float
    ipa: str
    pos: str
    meaning_vi: str
    example_en: str
    example_vi: str
    topic: str
    bounding_box: BoundingBoxResponse
    is_saved: bool = False
    word_id: uuid.UUID | None = None

    model_config = {"from_attributes": True}


class ScanResponse(BaseModel):
    """Response của POST /scans."""
    id: uuid.UUID
    status: str                    # "ok" | "no_object"
    image_url: str                 # presigned URL (TTL 1 giờ)
    items: list[ScanItemResponse]
    object_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


class QuotaResponse(BaseModel):
    """Response của GET /scans/quota."""
    used: int
    limit: int
    remaining: int
    reset_at: str                  # ISO 8601 timestamp — thời điểm reset quota


class SaveScanItemRequest(BaseModel):
    is_saved: bool


class SavedWordResponse(BaseModel):
    id: uuid.UUID
    word_id: uuid.UUID | None = None
    label: str
    ipa: str
    pos: str
    meaning_vi: str
    example_en: str
    example_vi: str
    topic: str
    is_saved: bool
    created_at: datetime

    model_config = {"from_attributes": True}
