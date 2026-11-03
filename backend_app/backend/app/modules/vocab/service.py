"""
app/modules/vocab/service.py

Business logic cho vocab module.
  - Lấy danh sách từ (lọc theo topic, tìm kiếm, phân trang)
  - Lấy chi tiết một từ theo ID hoặc lemma
  - Tìm từ theo lemma (dùng bởi scan service)
"""

from __future__ import annotations

import math
from typing import Optional

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.models.word import Word

from .schemas import WordListResponse, WordResponse


class VocabService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    # ── List ─────────────────────────────────────────────────────────────────

    async def list_words(
        self,
        *,
        topic: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> WordListResponse:
        """
        Lấy danh sách từ với filter và phân trang.
        - topic: lọc theo chủ đề (food, animal, ...)
        - search: tìm theo lemma hoặc meaning_vi (case-insensitive)
        - page: bắt đầu từ 1
        - page_size: 1–100
        """
        page_size = max(1, min(page_size, 100))
        page = max(1, page)
        offset = (page - 1) * page_size

        stmt = select(Word)

        if topic:
            stmt = stmt.where(Word.topic == topic)

        if search:
            pattern = f"%{search.lower()}%"
            stmt = stmt.where(
                or_(
                    Word.lemma.ilike(pattern),
                    Word.meaning_vi.ilike(pattern),
                )
            )

        # Tổng số bản ghi
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_result = await self._db.execute(count_stmt)
        total: int = total_result.scalar_one()

        # Lấy trang hiện tại
        stmt = stmt.order_by(Word.lemma).offset(offset).limit(page_size)
        result = await self._db.execute(stmt)
        words = result.scalars().all()

        return WordListResponse(
            items=[WordResponse.model_validate(w) for w in words],
            total=total,
            page=page,
            page_size=page_size,
            has_next=(page * page_size) < total,
        )

    # ── Detail ────────────────────────────────────────────────────────────────

    async def get_word_by_id(self, word_id: str) -> Optional[Word]:
        """Lấy Word theo UUID."""
        import uuid as _uuid
        try:
            uid = _uuid.UUID(word_id)
        except ValueError:
            return None
        result = await self._db.execute(select(Word).where(Word.id == uid))
        return result.scalar_one_or_none()

    async def get_word_by_lemma(self, lemma: str) -> Optional[Word]:
        """Lấy Word theo lemma (lowercase, exact match)."""
        result = await self._db.execute(
            select(Word).where(Word.lemma == lemma.lower().strip())
        )
        return result.scalar_one_or_none()

    # ── Topics ────────────────────────────────────────────────────────────────

    async def list_topics(self) -> list[str]:
        """Lấy danh sách tất cả chủ đề có từ trong catalog."""
        result = await self._db.execute(
            select(Word.topic).distinct().order_by(Word.topic)
        )
        return list(result.scalars().all())

