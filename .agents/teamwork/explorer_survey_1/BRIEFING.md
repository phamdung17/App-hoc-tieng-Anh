# BRIEFING — 2026-11-03T14:02:00Z

## Mission
Investigate Backend FastAPI & Database modules, CORS/settings, docker-compose, Alembic migrations, progress service activity recording, and seed data requirements.

## 🔒 My Identity
- Archetype: explorer
- Roles: investigator, analyzer, synthesizer
- Working directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_1
- Original parent: f77a5a9e-f4c7-44f1-b367-65763f7a5895
- Milestone: backend-survey

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Do NOT modify, write, or create any code files in the repository
- Write only inside working directory .agents/teamwork/explorer_survey_1/

## Current Parent
- Conversation ID: f77a5a9e-f4c7-44f1-b367-65763f7a5895
- Updated: 2026-11-03T13:51:20Z

## Investigation State
- **Explored paths**:
  - `backend_app/backend/app/core/config/settings.py` & `.env`
  - `docker-compose.yml`
  - `backend_app/backend/alembic/env.py` & `alembic/versions/`
  - `backend_app/backend/app/modules/learning/service.py`, `schemas.py`, `router.py`
  - `backend_app/backend/app/modules/progress/service.py`, `schemas.py`
  - `backend_app/backend/app/core/models/learning.py`, `word.py`, `progress.py`
  - `app_hoc_tieng_anh/lib/features/learning/` (exercise models and mock repository)
- **Key findings**:
  - Pydantic Settings v2 crashes with `JSONDecodeError` on comma-separated `CORS_ORIGINS` in `.env` because field is typed as `list[str]`. Fix: `list[str] | str`.
  - `docker-compose.yml` has invalid paths `./backend` instead of `./backend_app/backend`.
  - `alembic/env.py` passes psycopg2 sync URL to `async_engine_from_config`, raising `InvalidRequestError` and failing migrations. Fix: use `settings.DATABASE_URL` (asyncpg) directly.
  - `submit_lesson` in `learning/service.py` fails to call `ProgressService.record_activity`. Moreover, `record_activity` increments `user.xp_total`, so `submit_lesson`'s SQL `update(User)` must be removed to avoid double XP.
  - Complete seed data designed: 2 Learning Paths (A1, A2), 5 Units, 9 Lessons with all 5 exercise types in JSONB, and 28 curated words across 4 topics.
- **Unexplored areas**: None. Survey is complete.

## Key Decisions Made
- Fully documented all 5 investigation areas and seed architecture in `survey_backend.md`.
- Formulated 5-component handoff in `handoff.md`.

## Artifact Index
- survey_backend.md — Comprehensive findings on backend configuration, alembic, services, and models
- handoff.md — 5-component handoff report
- progress.md — Liveness heartbeat
- DISPATCH.md — Received instructions log
