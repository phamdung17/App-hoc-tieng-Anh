"""
app/modules/vocab/router.py

FastAPI router cho vocabulary catalog.
Endpoints:
  - GET /vocab              : Danh sách từ (có filter + pagination)
  - GET /vocab/{id}         : Chi tiết một từ
  - GET /vocab/search       : Tìm kiếm theo lemma
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User
from app.core.models.word import Word

from .schemas import WordListResponse, WordResponse

router = APIRouter(prefix="/vocab", tags=["vocabulary"])


# ── GET /vocab ────────────────────────────────────────────────────────────────

@router.get(
    "",
    response_model=WordListResponse,
    summary="Danh sách từ vựng",
)
async def list_words(
    topic: str | None = Query(None, description="Filter theo chủ đề (food, animal...)"),
    pos: str | None = Query(None, description="Filter theo part of speech (noun, verb...)"),
    page: int = Query(1, ge=1, description="Trang hiện tại"),
    page_size: int = Query(20, ge=1, le=100, description="Số từ mỗi trang"),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> WordListResponse:
    """
    Trả về danh sách từ có phân trang.
    Filter theo topic và/hoặc part of speech.
    """
    stmt = select(Word)
    count_stmt = select(func.count()).select_from(Word)

    if topic:
        stmt = stmt.where(Word.topic == topic.lower())
        count_stmt = count_stmt.where(Word.topic == topic.lower())
    if pos:
        stmt = stmt.where(Word.pos == pos.lower())
        count_stmt = count_stmt.where(Word.pos == pos.lower())

    total: int = (await db.execute(count_stmt)).scalar_one()

    offset = (page - 1) * page_size
    stmt = stmt.order_by(Word.lemma).offset(offset).limit(page_size)
    words = list((await db.execute(stmt)).scalars().all())

    return WordListResponse(
        items=[WordResponse.model_validate(w) for w in words],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(offset + page_size) < total,
    )


# ── GET /vocab/search ─────────────────────────────────────────────────────────

@router.get(
    "/search",
    response_model=WordListResponse,
    summary="Tìm kiếm từ vựng",
)
async def search_words(
    q: str = Query(..., min_length=1, max_length=50, description="Từ khóa tìm kiếm"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> WordListResponse:
    """
    Tìm kiếm từ theo lemma hoặc meaning_vi (contains search).
    """
    q_lower = q.lower().strip()
    where_clause = or_(
        Word.lemma.ilike(f"%{q_lower}%"),
        Word.meaning_vi.ilike(f"%{q_lower}%"),
    )

    count_stmt = select(func.count()).select_from(Word).where(where_clause)
    total: int = (await db.execute(count_stmt)).scalar_one()

    offset = (page - 1) * page_size
    stmt = (
        select(Word)
        .where(where_clause)
        .order_by(Word.lemma)
        .offset(offset)
        .limit(page_size)
    )
    words = list((await db.execute(stmt)).scalars().all())

    return WordListResponse(
        items=[WordResponse.model_validate(w) for w in words],
        total=total,
        page=page,
        page_size=page_size,
        has_next=(offset + page_size) < total,
    )


# ── GET /vocab/{id} ───────────────────────────────────────────────────────────

@router.get(
    "/{word_id}",
    response_model=WordResponse,
    summary="Chi tiết một từ",
)
async def get_word(
    word_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> WordResponse:
    """Lấy thông tin đầy đủ của một từ theo ID."""
    word = await db.get(Word, word_id)
    if word is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "WORD_NOT_FOUND", "message": f"Word {word_id} not found"},
        )
    return WordResponse.model_validate(word)
