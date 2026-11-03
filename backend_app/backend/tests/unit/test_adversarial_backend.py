"""
tests/unit/test_adversarial_backend.py

Adversarial Verification Suite by challenger_prod_1:
1. CORS_ORIGINS parsing stress tests (edge cases, whitespace, malformed JSON, empty, wildcard).
2. Alembic config & asyncpg dialect without psycopg2.
3. Learning submit_lesson & ProgressService.record_activity (no double XP, streak tracking, daily activities).
4. Seed data structure, exercise models, vocabulary coverage, and idempotency.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock

import pytest
from sqlalchemy import pool
from sqlalchemy.ext.asyncio import AsyncEngine, async_engine_from_config

from app.core.config.settings import Settings
from app.core.models.learning import LearningPath, Lesson, Unit, UserLessonProgress
from app.core.models.progress import UserDailyActivity
from app.core.models.user import User
from app.core.models.word import Word
from app.db.seeds import SEED_PATHS, SEED_WORDS, deterministic_uuid, seed_all
from app.modules.learning.service import LearningService
from app.modules.progress.service import ProgressService, _compute_streaks


# ─────────────────────────────────────────────────────────────────────────────
# 1. CORS_ORIGINS ADVERSARIAL STRESS TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_cors_origins_adversarial_inputs() -> None:
    defaults = {
        "STORAGE_ENDPOINT": "http://s3",
        "STORAGE_ACCESS_KEY": "k",
        "STORAGE_SECRET_KEY": "s",
        "GEMINI_API_KEY": "g",
    }

    test_cases = [
        ("standard_comma", "http://localhost:3000,http://localhost:8000", ["http://localhost:3000", "http://localhost:8000"]),
        ("single_url", "http://localhost:3000", ["http://localhost:3000"]),
        ("excessive_whitespace", "  http://localhost:3000 ,  \thttp://localhost:8000 \n , https://myapp.com  ", ["http://localhost:3000", "http://localhost:8000", "https://myapp.com"]),
        ("json_array", '["http://localhost:3000", "http://localhost:8000"]', ["http://localhost:3000", "http://localhost:8000"]),
        ("json_with_empty_items", '[" http://localhost:3000 ", "", "   ", "http://localhost:8000"]', ["http://localhost:3000", "http://localhost:8000"]),
        ("malformed_json_unquoted", "[http://localhost:3000, http://localhost:8000]", ["[http://localhost:3000", "http://localhost:8000]"]),
        ("malformed_json_trailing_comma", '["http://localhost:3000",]', ['["http://localhost:3000"', "]"]),
        ("malformed_json_unclosed", '["http://localhost:3000"', ['["http://localhost:3000"']),
        ("empty_string", "", []),
        ("whitespace_only", "   \t\n  ", []),
        ("commas_only", ",,, , ,,", []),
        ("list_input", ["http://localhost:3000", "http://localhost:8000"], ["http://localhost:3000", "http://localhost:8000"]),
        ("list_with_whitespace", [" http://localhost:3000 ", "", "  ", "http://localhost:8000"], ["http://localhost:3000", "http://localhost:8000"]),
        ("tuple_input", ("http://localhost:3000", "http://localhost:8000"), ["http://localhost:3000", "http://localhost:8000"]),
        ("set_input", {"http://localhost:3000"}, ["http://localhost:3000"]),
        ("wildcard", "*", ["*"]),
        ("trailing_comma", "http://a.com, http://b.com, ", ["http://a.com", "http://b.com"]),
    ]

    for name, raw_val, expected in test_cases:
        s = Settings(CORS_ORIGINS=raw_val, **defaults)
        assert isinstance(s.CORS_ORIGINS, list), f"Failed for {name}: expected list"
        if isinstance(raw_val, set):
            assert set(s.CORS_ORIGINS) == set(expected)
        else:
            assert s.CORS_ORIGINS == expected, f"Failed for {name}: {s.CORS_ORIGINS} != {expected}"


# ─────────────────────────────────────────────────────────────────────────────
# 2. ALEMBIC CONFIG & ASYNC ENGINE TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_alembic_async_engine_and_dialect() -> None:
    from app.core.config import settings

    assert settings.DATABASE_URL.startswith("postgresql+asyncpg://"), "Must use postgresql+asyncpg://"
    
    cfg = {"sqlalchemy.url": settings.DATABASE_URL}
    engine = async_engine_from_config(cfg, prefix="sqlalchemy.", poolclass=pool.NullPool)
    assert isinstance(engine, AsyncEngine)
    assert engine.dialect.driver == "asyncpg"

    offline_url = settings.DATABASE_URL.replace("+asyncpg", "")
    assert not "+asyncpg" in offline_url
    assert offline_url.startswith("postgresql://")


# ─────────────────────────────────────────────────────────────────────────────
# 3. SUBMIT_LESSON & PROGRESS_SERVICE INTEGRATION (NO DOUBLE XP & STREAK)
# ─────────────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_submit_lesson_and_progress_integration_stateful() -> None:
    user_id = uuid.uuid4()
    lesson_id = uuid.uuid4()
    unit_id = uuid.uuid4()

    state = {
        "user": User(
            id=user_id,
            email="learner@lingoup.com",
            hashed_password="pw",
            xp_total=100,
            streak_days=0,
            last_activity_date=None,
        ),
        "lesson": Lesson(
            id=lesson_id,
            unit_id=unit_id,
            title="Adversarial Verification Lesson",
            lesson_type="vocabulary",
            xp_reward=25,
            order_index=1,
        ),
        "progress": None,
        "daily_activities": {},
    }

    class FakeSession:
        def __init__(self, s):
            self.s = s

        def add(self, obj):
            if isinstance(obj, UserLessonProgress):
                self.s["progress"] = obj
            elif isinstance(obj, UserDailyActivity):
                self.s["daily_activities"][(obj.user_id, obj.activity_date)] = obj

        async def flush(self):
            pass

        async def commit(self):
            pass

        async def execute(self, stmt):
            stmt_str = str(stmt).lower()
            if "from lessons" in stmt_str:
                return MagicMock(scalar_one_or_none=MagicMock(return_value=self.s["lesson"]))
            elif "from user_lesson_progress" in stmt_str:
                return MagicMock(scalar_one_or_none=MagicMock(return_value=self.s["progress"]))
            elif "from user_daily_activities" in stmt_str:
                today = datetime.now(timezone.utc).date()
                act = self.s["daily_activities"].get((user_id, today))
                return MagicMock(scalar_one_or_none=MagicMock(return_value=act))
            elif "from users" in stmt_str:
                u = self.s["user"]
                return MagicMock(
                    scalar_one_or_none=MagicMock(return_value=u),
                    one_or_none=MagicMock(return_value=MagicMock(xp_total=u.xp_total, streak_days=u.streak_days)),
                )
            elif "from units" in stmt_str:
                return MagicMock(scalar_one_or_none=MagicMock(return_value=None))
            return MagicMock(scalar_one_or_none=MagicMock(return_value=None), one_or_none=MagicMock(return_value=None))

    session = FakeSession(state)
    learning_service = LearningService(db=session)

    # 1. First completion with passing score (70)
    res1 = await learning_service.submit_lesson(
        lesson_id=lesson_id,
        user_id=user_id,
        score=70,
        time_spent_seconds=75,
    )
    assert res1.xp_earned == 25
    assert state["user"].xp_total == 125
    assert state["user"].streak_days == 1
    today = datetime.now(timezone.utc).date()
    daily_act = state["daily_activities"][(user_id, today)]
    assert daily_act.xp_earned == 25
    assert daily_act.lessons_completed == 1

    # 2. Retake already completed lesson -> xp_earned MUST be 0 (NO DOUBLE XP!)
    res2 = await learning_service.submit_lesson(
        lesson_id=lesson_id,
        user_id=user_id,
        score=95,
        time_spent_seconds=60,
    )
    assert res2.xp_earned == 0
    assert state["user"].xp_total == 125  # Unchanged!
    assert state["user"].streak_days == 1  # Unchanged!
    assert daily_act.xp_earned == 25      # Unchanged!
    assert daily_act.lessons_completed == 1

    # 3. Consecutive day progression: yesterday -> today
    yesterday = today - timedelta(days=1)
    state["user"].last_activity_date = datetime.combine(yesterday, datetime.min.time(), tzinfo=timezone.utc)
    state["user"].streak_days = 3

    progress_service = ProgressService(db=session)
    await progress_service.record_activity(user_id=user_id, xp_earned=10, lessons_completed=1, minutes_studied=5)
    assert state["user"].streak_days == 4
    assert state["user"].xp_total == 135

    # 4. Missed day reset: 2 days gap -> reset to 1
    two_days_ago = today - timedelta(days=2)
    state["user"].last_activity_date = datetime.combine(two_days_ago, datetime.min.time(), tzinfo=timezone.utc)
    state["user"].streak_days = 10

    await progress_service.record_activity(user_id=user_id, xp_earned=20, lessons_completed=1, minutes_studied=5)
    assert state["user"].streak_days == 1
    assert state["user"].xp_total == 155


# ─────────────────────────────────────────────────────────────────────────────
# 4. SEED DATA STRUCTURE & IDEMPOTENCY TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_seed_data_structure_and_coverage() -> None:
    # 2 Paths
    assert len(SEED_PATHS) == 2
    levels = [p["level"] for p in SEED_PATHS]
    assert "A1" in levels and "A2" in levels

    # 5 Units
    total_units = sum(len(p.get("units", [])) for p in SEED_PATHS)
    assert total_units == 5

    # Lessons and Exercise Types
    total_lessons = 0
    exercise_types = set()
    total_exercises = 0

    for path in SEED_PATHS:
        for unit in path.get("units", []):
            for lesson in unit.get("lessons", []):
                total_lessons += 1
                content = lesson.get("content_data", {})
                exercises = content.get("exercises", [])
                total_exercises += len(exercises)
                for ex in exercises:
                    exercise_types.add(ex.get("type"))
                    # Each exercise must have id, type, prompt
                    assert "id" in ex
                    assert "type" in ex
                    assert "prompt" in ex

    assert total_lessons >= 9
    assert total_exercises >= 30
    expected_types = {"choice", "wordBank", "matchPairs", "listening", "speaking"}
    assert expected_types.issubset(exercise_types), f"Missing exercise types: {expected_types - exercise_types}"

    # 30 Vocabulary Words across 4 topics
    assert len(SEED_WORDS) >= 28
    topics = {w.get("topic") for w in SEED_WORDS}
    expected_topics = {"greeting", "food", "travel", "daily"}
    assert expected_topics.issubset(topics), f"Missing topics: {expected_topics - topics}"

    for w in SEED_WORDS:
        assert w.get("lemma")
        assert w.get("meaning_vi")
        assert w.get("topic") in expected_topics
        assert w.get("is_seeded") is True


@pytest.mark.asyncio
async def test_seed_idempotency_simulation() -> None:
    class MockResult:
        def __init__(self, items):
            self._items = items

        def scalars(self):
            return self

        def first(self):
            return self._items[0] if self._items else None

    class MockAsyncSession:
        def __init__(self):
            self.objects = {}
            self.words_by_lemma = {}

        async def get(self, model_cls, obj_id):
            return self.objects.get((model_cls, obj_id))

        def add(self, obj):
            key = (type(obj), obj.id)
            self.objects[key] = obj
            if type(obj).__name__ == "Word":
                self.words_by_lemma[obj.lemma] = obj

        async def execute(self, stmt):
            found = None
            try:
                params = stmt.compile().params
                for p_val in params.values():
                    if isinstance(p_val, str) and p_val in self.words_by_lemma:
                        found = self.words_by_lemma[p_val]
                        break
                    elif isinstance(p_val, uuid.UUID) and (Word, p_val) in self.objects:
                        found = self.objects[(Word, p_val)]
                        break
            except Exception:
                pass
            return MockResult([found] if found else [])

        async def flush(self):
            pass

    session = MockAsyncSession()
    stats1 = await seed_all(session)
    assert stats1["paths"] == 2
    assert stats1["units"] == 5
    assert stats1["lessons"] >= 9
    assert stats1["words"] >= 28

    # Second run should insert 0 new items
    stats2 = await seed_all(session)
    assert stats2["paths"] == 0
    assert stats2["units"] == 0
    assert stats2["lessons"] == 0
    assert stats2["words"] == 0

