"""
app/modules/learning/service.py

LearningService — business logic cho lộ trình học.

Responsibilities:
  - list_paths        : danh sách tất cả paths + progress summary của user
  - get_path_detail   : path đầy đủ với units/lessons + inject status từ progress
  - get_lesson_detail : chi tiết lesson + content_data + progress
  - submit_lesson     : chấm điểm, cộng XP, mở khoá bài tiếp theo

Unlock rule:
  Sau khi hoàn thành lesson (score >= 70), tự động set status="available"
  cho lesson tiếp theo (order_index + 1) trong cùng unit. Nếu hết unit →
  unlock lesson đầu tiên (order_index nhỏ nhất) của unit tiếp theo.

Init progress:
  Khi user lần đầu gọi list_paths, nếu chưa có bất kỳ progress record nào
  cho path, tự động tạo record "available" cho lesson đầu tiên của path.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.models.learning import (
    LearningPath,
    Lesson,
    Unit,
    UserLessonProgress,
)
from app.core.models.user import User

from .schemas import (
    LearningPathResponse,
    LearningPathSummary,
    LessonDetailResponse,
    LessonSummary,
    SubmitLessonResponse,
    UnitResponse,
)


class LearningService:
    """Service xử lý toàn bộ logic học tập."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ── Helpers ───────────────────────────────────────────────────────────

    async def _get_progress_map(
        self, user_id: uuid.UUID, lesson_ids: list[uuid.UUID]
    ) -> dict[uuid.UUID, UserLessonProgress]:
        """Lấy dict {lesson_id: UserLessonProgress} cho danh sách lesson_ids."""
        if not lesson_ids:
            return {}
        result = await self.db.execute(
            select(UserLessonProgress).where(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.lesson_id.in_(lesson_ids),
            )
        )
        records = result.scalars().all()
        return {r.lesson_id: r for r in records}

    async def _ensure_first_lesson_available(
        self, path_id: uuid.UUID, user_id: uuid.UUID
    ) -> None:
        """
        Init progress: nếu user chưa có bất kỳ progress record nào cho path này,
        tự động tạo record status="available" cho lesson đầu tiên.
        """
        # Lấy unit đầu tiên của path (order_index nhỏ nhất)
        unit_result = await self.db.execute(
            select(Unit)
            .where(Unit.path_id == path_id)
            .order_by(Unit.order_index.asc())
            .limit(1)
        )
        first_unit = unit_result.scalar_one_or_none()
        if not first_unit:
            return

        # Lấy lesson đầu tiên của unit đó
        lesson_result = await self.db.execute(
            select(Lesson)
            .where(Lesson.unit_id == first_unit.id)
            .order_by(Lesson.order_index.asc())
            .limit(1)
        )
        first_lesson = lesson_result.scalar_one_or_none()
        if not first_lesson:
            return

        # Kiểm tra đã có progress record chưa
        existing = await self.db.execute(
            select(UserLessonProgress).where(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.lesson_id == first_lesson.id,
            )
        )
        if existing.scalar_one_or_none() is not None:
            return

        # Chưa có → tạo mới
        progress = UserLessonProgress(
            user_id=user_id,
            lesson_id=first_lesson.id,
            status="available",
        )
        self.db.add(progress)
        await self.db.flush()

    # ── Public API ────────────────────────────────────────────────────────

    async def list_paths(self, user_id: uuid.UUID) -> list[LearningPathSummary]:
        """
        Lấy tất cả LearningPath đang active.
        Với mỗi path, tính total_lessons và completed_lessons của user.
        Tự động init progress cho lần đầu.
        """
        paths_result = await self.db.execute(
            select(LearningPath)
            .where(LearningPath.is_active == True)  # noqa: E712
            .order_by(LearningPath.level.asc())
        )
        paths = paths_result.scalars().all()

        summaries: list[LearningPathSummary] = []
        for path in paths:
            # Init progress nếu chưa có
            await self._ensure_first_lesson_available(path.id, user_id)

            # Đếm tổng số lessons trong path
            total_q = await self.db.execute(
                select(func.count(Lesson.id))
                .join(Unit, Lesson.unit_id == Unit.id)
                .where(Unit.path_id == path.id)
            )
            total_lessons: int = total_q.scalar() or 0

            # Đếm số lessons đã completed
            completed_q = await self.db.execute(
                select(func.count(UserLessonProgress.id))
                .join(Lesson, UserLessonProgress.lesson_id == Lesson.id)
                .join(Unit, Lesson.unit_id == Unit.id)
                .where(
                    Unit.path_id == path.id,
                    UserLessonProgress.user_id == user_id,
                    UserLessonProgress.status == "completed",
                )
            )
            completed_lessons: int = completed_q.scalar() or 0

            summaries.append(
                LearningPathSummary(
                    id=path.id,
                    title=path.title,
                    level=path.level,
                    thumbnail_url=path.thumbnail_url,
                    total_lessons=total_lessons,
                    completed_lessons=completed_lessons,
                )
            )

        await self.db.commit()
        return summaries

    async def get_path_detail(
        self, path_id: uuid.UUID, user_id: uuid.UUID
    ) -> LearningPathResponse | None:
        """
        Lấy LearningPath đầy đủ với units + lessons.
        Inject status và best_score từ user_lesson_progress vào từng lesson.
        """
        path_result = await self.db.execute(
            select(LearningPath).where(LearningPath.id == path_id)
        )
        path = path_result.scalar_one_or_none()
        if not path:
            return None

        # Lấy tất cả units (sắp xếp theo order_index)
        units_result = await self.db.execute(
            select(Unit)
            .where(Unit.path_id == path_id)
            .order_by(Unit.order_index.asc())
        )
        units = units_result.scalars().all()

        # Thu thập tất cả lesson_ids để query progress 1 lần
        all_lesson_ids: list[uuid.UUID] = []
        unit_lessons_map: dict[uuid.UUID, list[Lesson]] = {}

        for unit in units:
            lessons_result = await self.db.execute(
                select(Lesson)
                .where(Lesson.unit_id == unit.id)
                .order_by(Lesson.order_index.asc())
            )
            lessons = lessons_result.scalars().all()
            unit_lessons_map[unit.id] = list(lessons)
            all_lesson_ids.extend(l.id for l in lessons)

        progress_map = await self._get_progress_map(user_id, all_lesson_ids)

        # Build response
        unit_responses: list[UnitResponse] = []
        for unit in units:
            lessons = unit_lessons_map.get(unit.id, [])
            lesson_summaries: list[LessonSummary] = []
            for lesson in lessons:
                prog = progress_map.get(lesson.id)
                lesson_summaries.append(
                    LessonSummary(
                        id=lesson.id,
                        title=lesson.title,
                        lesson_type=lesson.lesson_type,
                        xp_reward=lesson.xp_reward,
                        order_index=lesson.order_index,
                        icon_name=lesson.icon_name,
                        status=prog.status if prog else "locked",
                        best_score=prog.best_score if prog else 0,
                    )
                )
            unit_responses.append(
                UnitResponse(
                    id=unit.id,
                    title=unit.title,
                    description=unit.description,
                    order_index=unit.order_index,
                    lessons=lesson_summaries,
                )
            )

        return LearningPathResponse(
            id=path.id,
            title=path.title,
            description=path.description,
            level=path.level,
            thumbnail_url=path.thumbnail_url,
            units=unit_responses,
        )

    async def get_lesson_detail(
        self, lesson_id: uuid.UUID, user_id: uuid.UUID
    ) -> LessonDetailResponse | None:
        """
        Lấy Lesson đầy đủ với content_data, kèm thông tin progress của user.
        """
        lesson_result = await self.db.execute(
            select(Lesson).where(Lesson.id == lesson_id)
        )
        lesson = lesson_result.scalar_one_or_none()
        if not lesson:
            return None

        prog_result = await self.db.execute(
            select(UserLessonProgress).where(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.lesson_id == lesson_id,
            )
        )
        prog = prog_result.scalar_one_or_none()

        return LessonDetailResponse(
            id=lesson.id,
            title=lesson.title,
            lesson_type=lesson.lesson_type,
            xp_reward=lesson.xp_reward,
            order_index=lesson.order_index,
            icon_name=lesson.icon_name,
            content_data=lesson.content_data,
            status=prog.status if prog else "locked",
            best_score=prog.best_score if prog else 0,
            attempt_count=prog.attempt_count if prog else 0,
        )

    async def submit_lesson(
        self,
        lesson_id: uuid.UUID,
        user_id: uuid.UUID,
        score: int,
        time_spent_seconds: int,  # noqa: ARG002 — reserved for future analytics
    ) -> SubmitLessonResponse:
        """
        Nộp kết quả bài học.

        Flow:
          1. Lấy lesson và progress record hiện tại.
          2. Nếu score >= 70 → mark completed.
          3. Tính xp_earned: bằng lesson.xp_reward nếu lần đầu complete, else 0.
          4. Cộng xp vào users.xp_total.
          5. Update/create user_lesson_progress (best_score, attempt_count).
          6. Unlock lesson tiếp theo (trong unit hoặc unit tiếp theo).
          7. Return SubmitLessonResponse.
        """
        # 1. Lấy lesson
        lesson_result = await self.db.execute(
            select(Lesson).where(Lesson.id == lesson_id)
        )
        lesson = lesson_result.scalar_one_or_none()
        if not lesson:
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="Lesson not found")

        # Lấy progress record hiện tại
        prog_result = await self.db.execute(
            select(UserLessonProgress).where(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.lesson_id == lesson_id,
            )
        )
        prog = prog_result.scalar_one_or_none()

        # 2 & 3. Tính xp và status mới
        passed = score >= 70
        was_completed = prog.status == "completed" if prog else False
        xp_earned = lesson.xp_reward if (passed and not was_completed) else 0
        new_status = "completed" if passed else (prog.status if prog else "available")
        now = datetime.now(timezone.utc)

        # 4. Cộng XP vào user
        if xp_earned > 0:
            await self.db.execute(
                update(User)
                .where(User.id == user_id)
                .values(xp_total=User.xp_total + xp_earned)
            )

        # 5. Update / create progress record
        if prog is None:
            prog = UserLessonProgress(
                user_id=user_id,
                lesson_id=lesson_id,
                status=new_status,
                best_score=score,
                attempt_count=1,
                completed_at=now if passed else None,
            )
            self.db.add(prog)
        else:
            prog.attempt_count = (prog.attempt_count or 0) + 1
            prog.best_score = max(prog.best_score or 0, score)
            if passed and not was_completed:
                prog.status = "completed"
                prog.completed_at = now

        await self.db.flush()

        # 6. Unlock bài tiếp theo
        unlocked_lessons: list[str] = []
        if passed and not was_completed:
            unlocked = await self._unlock_next_lesson(lesson, user_id)
            unlocked_lessons = unlocked

        # Lấy xp_total mới nhất và streak_days
        user_result = await self.db.execute(
            select(User.xp_total, User.streak_days).where(User.id == user_id)
        )
        row = user_result.one_or_none()
        new_total_xp = row.xp_total if row else 0
        streak_days = row.streak_days if row else 0

        await self.db.commit()

        return SubmitLessonResponse(
            xp_earned=xp_earned,
            new_total_xp=new_total_xp,
            streak_days=streak_days,
            lesson_status=new_status,
            unlocked_lessons=unlocked_lessons,
        )

    # ── Unlock logic ──────────────────────────────────────────────────────

    async def _unlock_next_lesson(
        self, current_lesson: Lesson, user_id: uuid.UUID
    ) -> list[str]:
        """
        Tìm và unlock lesson tiếp theo:
          - Ưu tiên lesson kế tiếp trong cùng unit (order_index + 1).
          - Nếu hết unit → lesson đầu tiên của unit kế tiếp.
        Trả về list các lesson_id (str) vừa được unlock.
        """
        unlocked: list[str] = []

        # Tìm lesson tiếp theo trong cùng unit
        next_in_unit_result = await self.db.execute(
            select(Lesson)
            .where(
                Lesson.unit_id == current_lesson.unit_id,
                Lesson.order_index > current_lesson.order_index,
            )
            .order_by(Lesson.order_index.asc())
            .limit(1)
        )
        next_lesson = next_in_unit_result.scalar_one_or_none()

        if next_lesson is None:
            # Hết unit → lấy unit tiếp theo
            current_unit_result = await self.db.execute(
                select(Unit).where(Unit.id == current_lesson.unit_id)
            )
            current_unit = current_unit_result.scalar_one_or_none()
            if not current_unit:
                return unlocked

            next_unit_result = await self.db.execute(
                select(Unit)
                .where(
                    Unit.path_id == current_unit.path_id,
                    Unit.order_index > current_unit.order_index,
                )
                .order_by(Unit.order_index.asc())
                .limit(1)
            )
            next_unit = next_unit_result.scalar_one_or_none()
            if not next_unit:
                return unlocked  # Đã học hết path

            # Lesson đầu tiên của unit tiếp theo
            first_lesson_result = await self.db.execute(
                select(Lesson)
                .where(Lesson.unit_id == next_unit.id)
                .order_by(Lesson.order_index.asc())
                .limit(1)
            )
            next_lesson = first_lesson_result.scalar_one_or_none()

        if next_lesson is None:
            return unlocked

        # Kiểm tra progress record của lesson tiếp theo
        existing_result = await self.db.execute(
            select(UserLessonProgress).where(
                UserLessonProgress.user_id == user_id,
                UserLessonProgress.lesson_id == next_lesson.id,
            )
        )
        existing = existing_result.scalar_one_or_none()

        if existing is None:
            # Tạo mới với status available
            new_prog = UserLessonProgress(
                user_id=user_id,
                lesson_id=next_lesson.id,
                status="available",
            )
            self.db.add(new_prog)
            unlocked.append(str(next_lesson.id))
        elif existing.status == "locked":
            existing.status = "available"
            unlocked.append(str(next_lesson.id))

        await self.db.flush()
        return unlocked
