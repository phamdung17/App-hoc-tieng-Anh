"""
app/modules/progress/router.py

FastAPI router cho Progress module.

Endpoints:
  GET /progress/summary    — Tóm tắt tiến trình của user hiện tại
  GET /progress/calendar   — Lịch học N ngày gần nhất (mặc định 30, tối đa 90)
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User

from .schemas import CalendarResponse, ProgressSummaryResponse
from .service import ProgressService

router = APIRouter(prefix="/progress", tags=["progress"])


# ── Dependency ────────────────────────────────────────────────────────────────

def _get_service(db: AsyncSession = Depends(get_db)) -> ProgressService:
    return ProgressService(db)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/summary",
    response_model=ProgressSummaryResponse,
    summary="Tóm tắt tiến trình học tập",
    description=(
        "Trả về XP tổng, streak hiện tại, mục tiêu ngày và "
        "thống kê hoạt động hôm nay của user đang đăng nhập."
    ),
)
async def get_summary(
    current_user: Annotated[User, Depends(get_current_user)],
    service: ProgressService = Depends(_get_service),
) -> ProgressSummaryResponse:
    return await service.get_summary(current_user)


@router.get(
    "/calendar",
    response_model=CalendarResponse,
    summary="Lịch học theo ngày",
    description=(
        "Trả về danh sách hoạt động N ngày gần nhất (mặc định 30, tối đa 90) "
        "kèm current streak và longest streak trong khoảng thời gian đó."
    ),
)
async def get_calendar(
    current_user: Annotated[User, Depends(get_current_user)],
    service: ProgressService = Depends(_get_service),
    days: int = Query(default=30, ge=1, le=90, description="Số ngày cần lấy (1–90)"),
) -> CalendarResponse:
    return await service.get_calendar(current_user.id, days=days)
