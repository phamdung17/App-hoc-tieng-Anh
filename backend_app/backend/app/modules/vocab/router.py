"""
app/modules/vocab/router.py

FastAPI router cho vocab module.
Endpoints:
  GET /vocab/topics       — Danh sách chủ đề có sẵn trong catalog
  GET /vocab              — Danh sách từ (filter topic + search, phân trang)
  GET /vocab/{id}         — Chi tiết một từ theo UUID
  GET /vocab/lemma/{word} — Chi tiết một từ theo lemma (tiện cho scan result)
"""

from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User

from .schemas import WordListResponse, WordResponse
from .service import VocabService

router = APIRouter(prefix="/vocab", tags=["vocab"])


# ── Dependency ────────────────────────────────────────────────────────────────

def get_vocab_service(db: AsyncSession = Depends(get_db)) -> VocabService:
    return VocabService(db=db)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/topics",
    response_model=list[str],
    summary="Lấy danh sách chủ đề từ vựng",
)
async def get_topics(
    _: User = Depends(get_current_user),
    service: VocabService = Depends(get_vocab_service),
) -> list[str]:
    """Trả danh sách các chủ đề (topic) hiện có trong catalog từ vựng."""
    return await service.list_topics()


@router.get(
    "",
    response_model=WordListResponse,
    summary="Danh sách từ vựng (có thể lọc và tìm kiếm)",
)
async def list_vocab(
    topic: Optional[str] = Query(None, description="Lọc theo chủ đề, VD: food, animal"),
    search: Optional[str] = Query(None, description="Tìm kiếm theo từ hoặc nghĩa tiếng Việt"),
    page: int = Query(1, ge=1, description="Số trang (bắt đầu từ 1)"),
    page_size: int = Query(20, ge=1, le=100, description="Số từ mỗi trang"),
    _: User = Depends(get_current_user),
    service: VocabService = Depends(get_vocab_service),
) -> WordListResponse:
    """
    Lấy danh sách từ vựng với phân trang.
    - Lọc theo `topic` (tùy chọn)
    - Tìm kiếm theo `search` khớp lemma hoặc nghĩa tiếng Việt (tùy chọn)
    """
    return await service.list_words(
        topic=topic,
        search=search,
        page=page,
        page_size=page_size,
    )


@router.get(
    "/lemma/{word}",
    response_model=WordResponse,
    summary="Lấy chi tiết từ theo lemma",
)
async def get_by_lemma(
    word: str,
    _: User = Depends(get_current_user),
    service: VocabService = Depends(get_vocab_service),
) -> WordResponse:
    """
    Lấy thẻ từ theo dạng gốc (lemma).
    Tiện dùng sau khi scan khi đã biết lemma từ Gemini.
    """
    db_word = await service.get_word_by_lemma(word)
    if db_word is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "WORD_NOT_FOUND", "message": f"Không tìm thấy từ '{word}' trong catalog."},
        )
    return WordResponse.model_validate(db_word)


@router.get(
    "/{word_id}",
    response_model=WordResponse,
    summary="Lấy chi tiết từ theo ID",
)
async def get_by_id(
    word_id: str,
    _: User = Depends(get_current_user),
    service: VocabService = Depends(get_vocab_service),
) -> WordResponse:
    """Lấy thẻ từ đầy đủ theo UUID."""
    db_word = await service.get_word_by_id(word_id)
    if db_word is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "WORD_NOT_FOUND", "message": "Không tìm thấy từ."},
        )
    return WordResponse.model_validate(db_word)

