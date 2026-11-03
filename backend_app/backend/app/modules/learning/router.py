"""
app/modules/learning/router.py

FastAPI router cho Learning module.

Endpoints:
  GET  /learning/paths                       → list_paths
  GET  /learning/paths/{path_id}             → get_path_detail
  GET  /learning/lessons/{lesson_id}         → get_lesson_detail
  POST /learning/lessons/{lesson_id}/submit  → submit_lesson

Tất cả đều yêu cầu authenticated user (get_current_user).
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User

from .schemas import (
    LearningPathResponse,
    LearningPathSummary,
    LessonDetailResponse,
    SubmitLessonRequest,
    SubmitLessonResponse,
)
from .service import LearningService

router = APIRouter(prefix="/learning", tags=["learning"])


# ── List paths ────────────────────────────────────────────────────────────────

@router.get(
    "/paths",
    response_model=list[LearningPathSummary],
    summary="Danh sách lộ trình học",
    description=(
        "Trả về tất cả lộ trình học đang active, kèm số bài học tổng "
        "và số bài đã hoàn thành của user. Tự động khởi tạo tiến độ "
        "nếu user chưa có record nào."
    ),
)
async def list_paths(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[LearningPathSummary]:
    service = LearningService(db)
    return await service.list_paths(user_id=current_user.id)


# ── Path detail ───────────────────────────────────────────────────────────────

@router.get(
    "/paths/{path_id}",
    response_model=LearningPathResponse,
    summary="Chi tiết lộ trình học",
    description=(
        "Trả về lộ trình học với đầy đủ units và lessons. "
        "Mỗi lesson được inject trạng thái tiến độ (locked/available/completed) "
        "và điểm cao nhất của user."
    ),
)
async def get_path_detail(
    path_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> LearningPathResponse:
    service = LearningService(db)
    path = await service.get_path_detail(path_id=path_id, user_id=current_user.id)
    if path is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learning path not found")
    return path


# ── Lesson detail ─────────────────────────────────────────────────────────────

@router.get(
    "/lessons/{lesson_id}",
    response_model=LessonDetailResponse,
    summary="Chi tiết bài học",
    description=(
        "Trả về toàn bộ nội dung bài học (content_data dạng JSON), "
        "kèm trạng thái và điểm cao nhất của user."
    ),
)
async def get_lesson_detail(
    lesson_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> LessonDetailResponse:
    service = LearningService(db)
    lesson = await service.get_lesson_detail(lesson_id=lesson_id, user_id=current_user.id)
    if lesson is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lesson not found")
    return lesson


# ── Submit lesson ─────────────────────────────────────────────────────────────

@router.post(
    "/lessons/{lesson_id}/submit",
    response_model=SubmitLessonResponse,
    summary="Nộp kết quả bài học",
    description=(
        "Chấm điểm bài học. Nếu score >= 70 thì bài được đánh dấu hoàn thành, "
        "XP được cộng vào tài khoản, và bài học tiếp theo được mở khoá."
    ),
)
async def submit_lesson(
    lesson_id: uuid.UUID,
    body: SubmitLessonRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SubmitLessonResponse:
    service = LearningService(db)
    return await service.submit_lesson(
        lesson_id=lesson_id,
        user_id=current_user.id,
        score=body.score,
        time_spent_seconds=body.time_spent_seconds,
    )
