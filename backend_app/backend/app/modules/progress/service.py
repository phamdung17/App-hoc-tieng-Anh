"""
app/modules/progress/service.py

ProgressService — logic theo dõi tiến trình học tập của user.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.models.progress import UserDailyActivity
from app.core.models.user import User

from .schemas import (
    DAILY_GOAL_XP,
    CalendarResponse,
    DailySummary,
    ProgressSummaryResponse,
)


def _today_utc() -> date:
    """Trả về ngày hiện tại theo UTC."""
    return datetime.now(timezone.utc).date()


def _compute_streaks(active_dates: set[date], today: date, days: int) -> tuple[int, int]:
    """
    Tính current_streak và longest_streak trong `days` ngày gần nhất.

    Returns:
        (current_streak, longest_streak)
    """
    current_streak = 0
    check_day = today
    while check_day in active_dates:
        current_streak += 1
        check_day -= timedelta(days=1)

    longest_streak = 0
    streak = 0
    start_date = today - timedelta(days=days - 1)
    for i in range(days):
        d = start_date + timedelta(days=i)
        if d in active_dates:
            streak += 1
            longest_streak = max(longest_streak, streak)
        else:
            streak = 0

    return current_streak, longest_streak


class ProgressService:
    """Service xử lý tiến trình học tập."""

    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    # ── Public API ────────────────────────────────────────────────────────

    async def get_summary(self, user: User) -> ProgressSummaryResponse:
        """
        Trả về tóm tắt tiến trình của user:
        - XP tổng, streak, last_activity_date từ User model
        - Hoạt động hôm nay từ UserDailyActivity
        """
        today = _today_utc()

        # Lấy activity hôm nay (nếu có)
        stmt = select(UserDailyActivity).where(
            UserDailyActivity.user_id == user.id,
            UserDailyActivity.activity_date == today,
        )
        result = await self._db.execute(stmt)
        today_activity: UserDailyActivity | None = result.scalar_one_or_none()

        today_xp = today_activity.xp_earned if today_activity else 0
        today_lessons = today_activity.lessons_completed if today_activity else 0
        today_minutes = today_activity.minutes_studied if today_activity else 0

        # Chuẩn hoá last_activity_date → string hoặc None
        last_date_str: str | None = None
        if user.last_activity_date is not None:
            lad = user.last_activity_date
            # last_activity_date được lưu là DateTime(timezone=True)
            if hasattr(lad, "date"):
                lad = lad.date()
            last_date_str = str(lad)

        return ProgressSummaryResponse(
            xp_total=user.xp_total,
            streak_days=user.streak_days,
            last_activity_date=last_date_str,
            today_xp=today_xp,
            today_lessons=today_lessons,
            today_minutes=today_minutes,
            daily_goal_xp=DAILY_GOAL_XP,
            daily_goal_reached=today_xp >= DAILY_GOAL_XP,
        )

    async def get_calendar(self, user_id: uuid.UUID, days: int = 30) -> CalendarResponse:
        """
        Trả về lịch học `days` ngày gần nhất.
        Ngày không có data được điền với zeros.
        """
        today = _today_utc()
        start_date = today - timedelta(days=days - 1)

        # Query tất cả activity trong khoảng [start_date, today]
        stmt = (
            select(UserDailyActivity)
            .where(
                UserDailyActivity.user_id == user_id,
                UserDailyActivity.activity_date >= start_date,
                UserDailyActivity.activity_date <= today,
            )
            .order_by(UserDailyActivity.activity_date.desc())
        )
        result = await self._db.execute(stmt)
        rows: list[UserDailyActivity] = list(result.scalars().all())

        # Build lookup: date → activity
        activity_map: dict[date, UserDailyActivity] = {r.activity_date: r for r in rows}
        active_dates: set[date] = set(activity_map.keys())

        # Tạo danh sách DailySummary cho từng ngày (mới nhất trước)
        daily_summaries: list[DailySummary] = []
        for i in range(days - 1, -1, -1):
            d = today - timedelta(days=i)
            act = activity_map.get(d)
            xp = act.xp_earned if act else 0
            daily_summaries.append(
                DailySummary(
                    date=str(d),
                    xp_earned=xp,
                    lessons_completed=act.lessons_completed if act else 0,
                    minutes_studied=act.minutes_studied if act else 0,
                    has_activity=xp > 0,
                )
            )

        total_days_studied = len(active_dates)
        current_streak, longest_streak = _compute_streaks(active_dates, today, days)

        return CalendarResponse(
            days=daily_summaries,
            total_days_studied=total_days_studied,
            current_streak=current_streak,
            longest_streak=longest_streak,
        )

    async def record_activity(
        self,
        user_id: uuid.UUID,
        xp_earned: int,
        lessons_completed: int = 1,
        minutes_studied: int = 5,
    ) -> None:
        """
        Upsert UserDailyActivity cho hôm nay và cập nhật streak + last_activity_date
        trên bảng users.
        """
        today = _today_utc()

        # Tìm activity hôm nay
        stmt = select(UserDailyActivity).where(
            UserDailyActivity.user_id == user_id,
            UserDailyActivity.activity_date == today,
        )
        result = await self._db.execute(stmt)
        activity: UserDailyActivity | None = result.scalar_one_or_none()

        if activity is not None:
            # Cộng dồn
            activity.xp_earned += xp_earned
            activity.lessons_completed += lessons_completed
            activity.minutes_studied += minutes_studied
        else:
            # Insert mới
            activity = UserDailyActivity(
                user_id=user_id,
                activity_date=today,
                xp_earned=xp_earned,
                lessons_completed=lessons_completed,
                minutes_studied=minutes_studied,
            )
            self._db.add(activity)

        # Cập nhật User: last_activity_date và streak_days
        user_stmt = select(User).where(User.id == user_id)
        user_result = await self._db.execute(user_stmt)
        user: User | None = user_result.scalar_one_or_none()

        if user is not None:
            # Tính streak
            last_date: date | None = None
            if user.last_activity_date is not None:
                lad = user.last_activity_date
                last_date = lad.date() if hasattr(lad, "date") else lad

            if last_date is None or last_date < today:
                # Chỉ cập nhật last_activity_date nếu hôm nay mới hơn
                user.last_activity_date = datetime.combine(  # type: ignore[assignment]
                    today, datetime.min.time()
                ).replace(tzinfo=timezone.utc)

                if last_date is None:
                    user.streak_days = 1
                elif last_date == today - timedelta(days=1):
                    # Hôm qua → chuỗi tiếp tục
                    user.streak_days += 1
                elif last_date < today - timedelta(days=1):
                    # Bỏ ngày → reset
                    user.streak_days = 1
                # last_date == today → không đổi streak (đã cộng XP rồi)

            # Cộng XP tổng
            user.xp_total += xp_earned

        await self._db.flush()
