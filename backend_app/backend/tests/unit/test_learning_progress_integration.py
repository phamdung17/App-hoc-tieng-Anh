"""
tests/unit/test_learning_progress_integration.py

Business logic and integration tests between LearningService and ProgressService:
1. Submit lesson passing score (>= 70) for first completion:
   - Marks lesson status as 'completed'
   - Triggers ProgressService.record_activity with lesson XP reward
   - Updates user daily activity and streak days
2. Submit lesson failing score (< 70):
   - Lesson status remains uncompleted
   - xp_earned is 0, lessons_completed is 0
3. Submit lesson retry on already completed lesson (Idempotency):
   - Does NOT re-award XP (no double XP counting)
4. Direct ProgressService.record_activity streak logic verification:
   - Consecutive day increments streak
   - Missed days resets streak to 1
   - Same-day activity accumulates XP without resetting streak
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.core.models.learning import Lesson, Unit, UserLessonProgress
from app.core.models.progress import UserDailyActivity
from app.core.models.user import User
from app.modules.learning.service import LearningService
from app.modules.progress.service import ProgressService, _compute_streaks


@pytest.mark.asyncio
async def test_submit_lesson_passed_first_time(mock_db_session: AsyncMock) -> None:
    """First-time completion passes score threshold and triggers ProgressService.record_activity."""
    user_id = uuid.uuid4()
    lesson_id = uuid.uuid4()
    unit_id = uuid.uuid4()

    mock_lesson = Lesson(
        id=lesson_id,
        unit_id=unit_id,
        title="Greetings & Introductions",
        lesson_type="standard",
        xp_reward=25,
        order_index=1,
    )

    # Database mock returns:
    # 1. select Lesson
    # 2. select UserLessonProgress (None: first time)
    # 3. unlock next lesson queries: next lesson in unit
    # 4. select User xp_total, streak_days
    mock_db_session.execute.side_effect = [
        MagicMock(scalar_one_or_none=MagicMock(return_value=mock_lesson)),
        MagicMock(scalar_one_or_none=MagicMock(return_value=None)),
        MagicMock(scalar_one_or_none=MagicMock(return_value=None)),  # no next lesson in unit
        MagicMock(scalar_one_or_none=MagicMock(return_value=None)),  # unit query
        MagicMock(one_or_none=MagicMock(return_value=MagicMock(xp_total=125, streak_days=4))),
    ]

    learning_service = LearningService(db=mock_db_session)

    with patch(
        "app.modules.learning.service.ProgressService.record_activity",
        new_callable=AsyncMock,
    ) as mock_record:
        response = await learning_service.submit_lesson(
            lesson_id=lesson_id,
            user_id=user_id,
            score=85,
            time_spent_seconds=120,
        )

        assert response.xp_earned == 25
        assert response.lesson_status == "completed"
        assert response.new_total_xp == 125
        assert response.streak_days == 4

        mock_record.assert_awaited_once_with(
            user_id=user_id,
            xp_earned=25,
            lessons_completed=1,
            minutes_studied=2,
        )


@pytest.mark.asyncio
async def test_submit_lesson_failed_below_threshold(mock_db_session: AsyncMock) -> None:
    """Failing score (< 70) earns 0 XP and does not count as completed lesson."""
    user_id = uuid.uuid4()
    lesson_id = uuid.uuid4()

    mock_lesson = Lesson(
        id=lesson_id,
        unit_id=uuid.uuid4(),
        title="Family Members",
        xp_reward=20,
        order_index=1,
    )

    mock_db_session.execute.side_effect = [
        MagicMock(scalar_one_or_none=MagicMock(return_value=mock_lesson)),
        MagicMock(scalar_one_or_none=MagicMock(return_value=None)),
        MagicMock(one_or_none=MagicMock(return_value=MagicMock(xp_total=100, streak_days=3))),
    ]

    learning_service = LearningService(db=mock_db_session)

    with patch(
        "app.modules.learning.service.ProgressService.record_activity",
        new_callable=AsyncMock,
    ) as mock_record:
        response = await learning_service.submit_lesson(
            lesson_id=lesson_id,
            user_id=user_id,
            score=55,
            time_spent_seconds=90,
        )

        assert response.xp_earned == 0
        assert response.lesson_status == "available"

        mock_record.assert_awaited_once_with(
            user_id=user_id,
            xp_earned=0,
            lessons_completed=0,
            minutes_studied=1,
        )


@pytest.mark.asyncio
async def test_submit_lesson_repeat_completed_no_double_xp(mock_db_session: AsyncMock) -> None:
    """Repeating an already completed lesson does not award duplicate XP (idempotency)."""
    user_id = uuid.uuid4()
    lesson_id = uuid.uuid4()

    mock_lesson = Lesson(
        id=lesson_id,
        unit_id=uuid.uuid4(),
        title="Colors",
        xp_reward=30,
        order_index=2,
    )
    existing_progress = UserLessonProgress(
        user_id=user_id,
        lesson_id=lesson_id,
        status="completed",
        best_score=80,
        attempt_count=1,
    )

    mock_db_session.execute.side_effect = [
        MagicMock(scalar_one_or_none=MagicMock(return_value=mock_lesson)),
        MagicMock(scalar_one_or_none=MagicMock(return_value=existing_progress)),
        MagicMock(one_or_none=MagicMock(return_value=MagicMock(xp_total=200, streak_days=5))),
    ]

    learning_service = LearningService(db=mock_db_session)

    with patch(
        "app.modules.learning.service.ProgressService.record_activity",
        new_callable=AsyncMock,
    ) as mock_record:
        response = await learning_service.submit_lesson(
            lesson_id=lesson_id,
            user_id=user_id,
            score=95,
            time_spent_seconds=60,
        )

        # xp_earned must be 0 to prevent double counting
        assert response.xp_earned == 0
        assert response.lesson_status == "completed"

        mock_record.assert_awaited_once_with(
            user_id=user_id,
            xp_earned=0,
            lessons_completed=0,
            minutes_studied=1,
        )


@pytest.mark.asyncio
async def test_progress_service_record_activity_streak_increments(
    mock_db_session: AsyncMock,
) -> None:
    """ProgressService increments streak when activity occurred yesterday."""
    user_id = uuid.uuid4()
    today = datetime.now(timezone.utc).date()
    yesterday = today - timedelta(days=1)

    mock_user = User(
        id=user_id,
        email="learner@lingoup.com",
        xp_total=100,
        streak_days=3,
        last_activity_date=datetime.combine(yesterday, datetime.min.time(), tzinfo=timezone.utc),
    )

    # 1. select UserDailyActivity (None -> first today)
    # 2. select User
    mock_db_session.execute.side_effect = [
        MagicMock(scalar_one_or_none=MagicMock(return_value=None)),
        MagicMock(scalar_one_or_none=MagicMock(return_value=mock_user)),
    ]

    service = ProgressService(db=mock_db_session)
    await service.record_activity(
        user_id=user_id,
        xp_earned=20,
        lessons_completed=1,
        minutes_studied=5,
    )

    assert mock_user.streak_days == 4
    assert mock_user.xp_total == 120
    assert mock_user.last_activity_date.date() == today


@pytest.mark.asyncio
async def test_progress_service_streak_computation_logic() -> None:
    """Test helper _compute_streaks across contiguous and broken date sequences."""
    today = date(2026, 11, 3)
    active_dates = {
        date(2026, 11, 3),
        date(2026, 11, 2),
        date(2026, 11, 1),
        # Gap on 2026-10-31
        date(2026, 10, 30),
        date(2026, 10, 29),
    }

    current, longest = _compute_streaks(active_dates, today, days=30)
    assert current == 3
    assert longest == 3
