## 2026-11-03T14:10:44Z
You are worker_m1, a teamwork_worker subagent.

Your Working Directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\worker_m1\
Original Request File: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md
Project Document: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\orchestrator\PROJECT.md
Survey Report: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_1\survey_backend.md
Audit Report: d:\LapTrinhMoBa\do_an_moba\AUDIT_REPORT.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY INSTRUCTIONS:
1. First, read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md.
2. Read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_1\survey_backend.md for detailed instructions and code locations.
3. Your scope is Milestone 1: Backend Core & Infrastructure Fixes.
   You EXCLUSIVELY own and will modify only these files:
   - `backend_app/backend/app/core/config/settings.py`
   - `docker-compose.yml`
   - `backend_app/backend/alembic/env.py`
   - `backend_app/backend/app/modules/learning/service.py`

4. Specific tasks:
   a. In `backend_app/backend/app/core/config/settings.py`:
      - Change `CORS_ORIGINS: list[str]` to `CORS_ORIGINS: list[str] | str = ["http://localhost:3000"]`.
      - Update `@field_validator("CORS_ORIGINS", mode="before")` so `parse_cors_origins` checks if `v` is a string: if it starts with "[" and ends with "]", parse via `json.loads`; otherwise split by "," and strip whitespace. Handle both formats robustly.
   b. In `docker-compose.yml`:
      - Update all paths pointing to `./backend` to `./backend_app/backend`:
        * `context: ./backend_app/backend`
        * `env_file: - ./backend_app/backend/.env`
        * `volumes: - ./backend_app/backend:/app`
   c. In `backend_app/backend/alembic/env.py`:
      - In `run_migrations_online()` (or `run_async_migrations`), ensure the database URL passed to `async_engine_from_config` uses `settings.DATABASE_URL` (the asyncpg URL, e.g. `postgresql+asyncpg://...`) and do NOT overwrite it with a `psycopg2` URL for the async engine.
   d. In `backend_app/backend/app/modules/learning/service.py`:
      - In `submit_lesson(...)`: import `ProgressService` from `app.modules.progress.service`.
      - When `passed` is True (or after calculating xp_earned), instantiate `ProgressService(self.db)` and call `await progress_service.record_activity(...)`:
        ```python
        await progress_service.record_activity(
            user_id=user_id,
            xp_earned=xp_earned,
            lessons_completed=1 if is_first_completion else 0,
            minutes_studied=max(1, time_spent_seconds // 60),
        )
        ```
      - IMPORTANT: Notice that `ProgressService.record_activity` ALREADY increments `user.xp_total += xp_earned`. Remove the redundant separate `user.xp_total += xp_earned` statement in `submit_lesson` so that XP is NOT double-counted!

5. Run python syntax/import checks or test commands on the modified files to verify there are no syntax errors or import issues (e.g., using `python -m py_compile ...` or `uv run python -c "from app.core.config.settings import settings; print(settings.CORS_ORIGINS)"` in `backend_app/backend`).
6. Write a comprehensive `handoff.md` in your working directory following the standard format (Observation, Logic Chain, Caveats, Conclusion, Verification Commands & Results).
7. Send a message to the orchestrator with your results.
