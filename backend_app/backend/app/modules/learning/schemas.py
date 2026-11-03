"""
app/modules/learning/schemas.py

Pydantic schemas cho Learning module:
  - LessonSummary          — tóm tắt bài học (dùng trong danh sách)
  - UnitResponse           — unit kèm danh sách lessons
  - LearningPathResponse   — path đầy đủ kèm units + lessons
  - LearningPathSummary    — tóm tắt path (dùng trong list paths)
  - LessonDetailResponse   — chi tiết bài học kèm content_data
  - SubmitLessonRequest    — payload nộp bài
  - SubmitLessonResponse   — kết quả sau khi nộp bài
"""

from __future__ import annotations

from typing import Any
import uuid

from pydantic import BaseModel, ConfigDict, Field


# ── Lesson ────────────────────────────────────────────────────────────────────

class LessonSummary(BaseModel):
    """Tóm tắt bài học — dùng trong danh sách của Unit."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    lesson_type: str
    xp_reward: int
    order_index: int
    icon_name: str | None = None
    # Progress fields (inject từ service)
    status: str = "locked"   # locked | available | completed
    best_score: int = 0


class LessonDetailResponse(BaseModel):
    """Chi tiết bài học kèm nội dung exercises."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    lesson_type: str
    xp_reward: int
    order_index: int
    icon_name: str | None = None
    content_data: Any | None = None   # JSONB — cấu trúc tùy loại bài
    # Progress fields (inject từ service)
    status: str = "locked"
    best_score: int = 0
    attempt_count: int = 0


# ── Unit ──────────────────────────────────────────────────────────────────────

class UnitResponse(BaseModel):
    """Unit kèm danh sách LessonSummary."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    description: str | None = None
    order_index: int
    lessons: list[LessonSummary] = Field(default_factory=list)


# ── LearningPath ──────────────────────────────────────────────────────────────

class LearningPathResponse(BaseModel):
    """Path đầy đủ kèm units + lessons (dùng ở màn hình chi tiết path)."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    description: str | None = None
    level: str
    thumbnail_url: str | None = None
    units: list[UnitResponse] = Field(default_factory=list)


class LearningPathSummary(BaseModel):
    """Tóm tắt path — dùng trong danh sách trang chủ."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    level: str
    thumbnail_url: str | None = None
    total_lessons: int = 0
    completed_lessons: int = 0


# ── Submit ────────────────────────────────────────────────────────────────────

class SubmitLessonRequest(BaseModel):
    """Payload gửi kết quả bài học."""

    score: int = Field(..., ge=0, le=100, description="Điểm số từ 0–100")
    time_spent_seconds: int = Field(..., ge=0, description="Thời gian làm bài (giây)")


class SubmitLessonResponse(BaseModel):
    """Kết quả trả về sau khi nộp bài."""

    xp_earned: int
    new_total_xp: int
    streak_days: int
    lesson_status: str              # completed | available (nếu chưa đạt)
    unlocked_lessons: list[str]     # list UUID string của các lesson vừa được unlock
