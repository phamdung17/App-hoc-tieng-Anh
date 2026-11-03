# HANDOFF REPORT — Backend Survey & Investigation (explorer_survey_1)

## 1. Observation
- **Observation 1 (CORS_ORIGINS Crash):**
  - File: `backend_app/backend/app/core/config/settings.py`, line 31:
    `CORS_ORIGINS: list[str] = ["http://localhost:3000"]`
  - File: `backend_app/backend/.env`, line 13:
    `CORS_ORIGINS=http://localhost:3000,http://localhost:8000`
  - Command: `python -c "from app.core.config.settings import settings"`
  - Error:
    ```text
    pydantic_settings.exceptions.SettingsError: error parsing value for field "CORS_ORIGINS" from source "DotEnvSettingsSource"
    json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
    ```
  - In `settings.py`, line 120 executes `settings: Settings = get_settings()` at module level, so any file importing `settings` or `app.core.config` crashes immediately.

- **Observation 2 (Docker Compose Path Mismatch):**
  - File: `docker-compose.yml`, lines 12–14:
    ```yaml
    backend:
      build:
        context: ./backend
        dockerfile: Dockerfile
    ```
  - Lines 18–19: `env_file: - ./backend/.env`
  - Lines 29–30: `volumes: - ./backend:/app`
  - The actual repository folder is `backend_app/backend/`. Running `docker compose up` fails with directory not found.

- **Observation 3 (Alembic Dialect Conflict):**
  - File: `backend_app/backend/alembic/env.py`, lines 39–41:
    ```python
    _sync_url = settings.DATABASE_URL.replace(
        "postgresql+asyncpg://", "postgresql+psycopg2://"
    )
    ```
  - Lines 80–87:
    ```python
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = _sync_url
    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    ```
  - Error: `sqlalchemy.exc.InvalidRequestError: The asyncpg dialect is required for async engines, got psycopg2`. `psycopg2` is not in `pyproject.toml` dependencies (only `asyncpg = "^0.30"`).

- **Observation 4 (Learning submit_lesson & Progress Disconnect + Double XP):**
  - File: `backend_app/backend/app/modules/learning/service.py`, lines 328–335:
    ```python
    # 4. Cộng XP vào user
    if xp_earned > 0:
        await self.db.execute(
            update(User)
            .where(User.id == user_id)
            .values(xp_total=User.xp_total + xp_earned)
        )
    ```
  - `ProgressService.record_activity` is never called.
  - File: `backend_app/backend/app/modules/progress/service.py`, lines 157–225:
    Line 223: `user.xp_total += xp_earned`
  - If `record_activity` is called while keeping the SQL `update(User)` in `submit_lesson`, `user.xp_total` will be incremented twice.

- **Observation 5 (Seed Data Schema & Requirements):**
  - Models in `app/core/models/learning.py`: `LearningPath`, `Unit`, `Lesson`, `UserLessonProgress`.
  - Models in `app/core/models/word.py`: `Word`.
  - Exercises in `Lesson.content_data` JSONB must match the 5 interactive exercise types used in Flutter: `choice`, `wordBank`, `matchPairs`, `listening`, `speaking`.
  - Directory `app/seed_data/courses/`, `exercises/`, `words/` currently only contains `README.md` and `.gitkeep`. Database has 0 seed rows.

---

## 2. Logic Chain
1. *From Obs 1*: Pydantic Settings v2 pre-parses complex types (`list[str]`) with `json.loads` before calling field validators. Because `.env` provides a comma-separated string `http://localhost:3000,http://localhost:8000`, `json.loads` fails. If the type is relaxed to `list[str] | str`, Pydantic passes the raw string to `parse_cors_origins`, which can split by `,` and return a clean `list[str]`.
2. *From Obs 2*: Docker build context and volume mounts resolve relative to the `docker-compose.yml` file located at the project root. Since the folder is named `backend_app/backend`, all occurrences of `./backend` must be changed to `./backend_app/backend`.
3. *From Obs 3*: Alembic's `run_async_migrations` initializes an `AsyncEngine`. `AsyncEngine` only accepts async DBAPI drivers (such as `postgresql+asyncpg://`). Supplying a psycopg2 URL to an async engine causes SQLAlchemy to reject it. Using `settings.DATABASE_URL` directly in `run_async_migrations` eliminates the dialect mismatch and dependency on missing `psycopg2`.
4. *From Obs 4*: `user_daily_activities` is empty because `record_activity` is never invoked in `submit_lesson`. However, `record_activity` already updates `user.xp_total`. Therefore, removing the separate `update(User)` in `submit_lesson` and calling `progress_service.record_activity(...)` ensures single-source XP addition and proper daily activity recording.
5. *From Obs 5*: To satisfy R3, a standalone seeder script (`seeder.py`) using deterministic UUIDs and `on_conflict_do_nothing` should be created to populate 2 Learning Paths, 5 Units, 9 Lessons (with all 5 exercise types in JSONB), and 28 Words across 4 topics (`greeting`, `food`, `travel`, `daily`).

---

## 3. Caveats
- Production database deployment: The audit was performed on static code and local environment configuration. When connecting to production PostgreSQL, migration `0001_initial_schema.py` requires `uuid-ossp` or `gen_random_uuid()` extension (supported out-of-the-box in Postgres 13+).
- Speech-to-Text / Text-to-Speech: In the exercise JSON schema, audio files for listening and speaking exercises are designed with text fallback (`audioText`, `phrase`) because Cloud TTS/STT services have not been integrated.
- S3 Storage credentials: If `STORAGE_ACCESS_KEY` or `STORAGE_SECRET_KEY` in `.env` is empty, scanning upload will fail unless mock storage is provided. However, learning paths and vocabulary do not depend on S3.

---

## 4. Conclusion
The Backend codebase has a solid architectural foundation (Clean Architecture, SQLAlchemy 2.0 async, 3 Alembic migrations), but is currently blocked by 3 configuration/dialect issues (P0-1 Settings, P0-4 Docker, P1-3 Alembic) and 1 logic disconnect (P1-2 Progress).
All issues have clear, localized, zero-side-effect solutions documented in `survey_backend.md`.
The seed data schema and concrete data for 2 Learning Paths, 5 Units, 9 Lessons, and 28 Vocabulary Words have been fully designed and are ready for implementation.

---

## 5. Verification Method
1. **Settings / CORS:**
   Run: `uv run python -c "from app.core.config.settings import settings; print(settings.CORS_ORIGINS)"` inside `backend_app/backend`.
   Expected: Prints `['http://localhost:3000', 'http://localhost:8000']` without `SettingsError`.
2. **Alembic Migrations:**
   Run: `uv run alembic upgrade head` inside `backend_app/backend`.
   Expected: Migrations `0001`, `0002`, `0003` apply cleanly with 0 errors.
3. **Docker Compose:**
   Run: `docker compose config` at project root.
   Expected: Validates compose file with context `backend_app/backend` and valid env file.
4. **Learning & Progress Service:**
   Run test submitting a lesson:
   Check `UserDailyActivity` table for entry on current UTC date with `xp_earned > 0` and `User.streak_days >= 1`.
