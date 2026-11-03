# Project: LingoUp Production Readiness (Frontend Flutter + Backend FastAPI)

## Architecture
- **Backend**: FastAPI 0.115+ (async/await), SQLAlchemy 2.0 Asyncio (asyncpg), Alembic, Pydantic Settings v2, PostgreSQL, Redis.
- **Frontend**: Flutter 3.47+ (Dart 3.13+), Riverpod 2.5+, GoRouter 14.2+, Dio 5.7+, Neumorphic / Duolingo-style UI.
- **Data Flow**:
  - Flutter Mobile App -> AppApi (Dio Singleton with RFC 3986 normalizePath interceptor) -> FastAPI Router (`/api/v1`) -> Service Layer -> Repository / SQLAlchemy Models -> PostgreSQL.
  - Learning Flow: UI -> LearningRepository (Facade) -> LearningApiService -> Backend `/api/v1/learning/...` -> On failure, transparent fallback to `MockLearningRepository.instance` with zero crash.
  - Progress Flow: `POST /api/v1/learning/lessons/{id}/submit` -> `LearningService.submit_lesson` -> calls `ProgressService.record_activity` -> updates `user_daily_activities`, `users.streak_days`, `users.xp_total`, and `user_lesson_progress`.

## Feature Inventory
| # | Feature | Description | Milestone | Source | Status |
|---|---------|-------------|-----------|--------|--------|
| 1 | CORS_ORIGINS Fix | Fix Pydantic Settings v2 JSONDecodeError on comma-separated string in .env | M1 | ORIGINAL_REQUEST §R1, AUDIT_REPORT §7.2 | VERIFIED |
| 2 | Docker Compose Context | Fix docker-compose.yml context and env path pointing to `./backend_app/backend` | M1 | ORIGINAL_REQUEST §R1, AUDIT_REPORT §7.2 | VERIFIED |
| 3 | Alembic Dialect Fix | Configure asyncpg dialect in alembic/env.py to prevent InvalidRequestError | M1 | ORIGINAL_REQUEST §R2, AUDIT_REPORT §7.2 | VERIFIED |
| 4 | Learning Streak & Progress | submit_lesson invokes ProgressService.record_activity, updates streak & daily activities without double XP | M1 | ORIGINAL_REQUEST §R2, AUDIT_REPORT §7.2 | VERIFIED |
| 5 | Android Cleartext Traffic | Add `android:usesCleartextTraffic="true"` to AndroidManifest.xml for local dev | M2 | ORIGINAL_REQUEST §R1, AUDIT_REPORT §7.2 | VERIFIED |
| 6 | iOS Hardware Permissions | Add NSCameraUsageDescription, NSMicrophoneUsageDescription, NSPhotoLibraryUsageDescription in Info.plist | M2 | ORIGINAL_REQUEST §R2, AUDIT_REPORT §7.2 | VERIFIED |
| 7 | RFC 3986 URL Resolution | Standardize AppConfig baseUrl and AppApi normalizePath interceptor to preserve `/api/v1` | M2 | ORIGINAL_REQUEST §R1, AUDIT_REPORT §7.2 | VERIFIED |
| 8 | LearningApiService & Fallback | Build LearningApiService and integrate into LearningPathPage and LessonPage with safe mock fallback | M2 | ORIGINAL_REQUEST §R2, AUDIT_REPORT §7.2 | VERIFIED |
| 9 | Database Seed Data Script | Idempotent seed script for 2 Paths, 5 Units, 10 Lessons with 32 Exercises, 30 Vocabularies in 4 Topics | M3 | ORIGINAL_REQUEST §R3, AUDIT_REPORT §7.2 | VERIFIED |
| 10 | Backend Automated Tests | pytest suite covering settings/CORS, auth flows, alembic config, lesson submit & streak updates (52 tests passed) | M4 | ORIGINAL_REQUEST §R4, AUDIT_REPORT §7.2 | VERIFIED |
| 11 | Frontend Automated Tests | flutter test suite covering AppApi URL resolver, LearningApiService, and mock fallback | M4 | ORIGINAL_REQUEST §R4, AUDIT_REPORT §7.2 | VERIFIED |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Backend Core & Infra Fixes | settings.py CORS, docker-compose.yml, alembic/env.py, learning submit_lesson | none | DONE |
| 2 | Frontend Platform & Learning Flow | AndroidManifest, iOS Info.plist, AppConfig, AppApi interceptor, LearningApiService & mock fallback | M1 (Interface) | DONE |
| 3 | Database Seed Data Script | app/db/seeds.py or scripts/seed_data.py with idempotent execution | M1 | DONE |
| 4 | Automated Verification Test Suites | pytest backend test suite + flutter test frontend test suite | M1, M2, M3 | DONE |

## Interface Contracts
### Learning Flow Contract: Frontend `LearningApiService` ↔ Backend `/api/v1/learning`
- `GET /api/v1/learning/paths`: Returns `List[LearningPathOut]` (id, code, title, level, is_active, total_units, total_lessons).
- `GET /api/v1/learning/paths/{path_id}`: Returns `LearningPathDetailOut` (id, title, units with lessons list).
- `GET /api/v1/learning/lessons/{lesson_id}`: Returns `LessonDetailOut` (id, title, xp_reward, content_data with exercises JSON array).
- `POST /api/v1/learning/lessons/{lesson_id}/submit`: Body: `{ score: int, time_spent_seconds: int }`. Returns `LessonSubmitResponse` (score, xp_earned, is_completed, streak_days).
- Fallback Contract: If any network exception, HTTP 4xx/5xx, or empty data occurs, Frontend `LearningRepository` intercepts exception and returns corresponding `MockLearningRepository.instance` entity without throwing or crashing.

### Streak & Progress Contract: Backend `submit_lesson` ↔ `ProgressService.record_activity`
- Signature: `await progress_service.record_activity(user_id=user_id, xp_earned=xp_earned, lessons_completed=1 if is_first_completion else 0, minutes_studied=max(1, time_spent_seconds // 60))`
- Side-effects: creates or updates `user_daily_activities` for today (UTC/local date), increments `streak_days` if consecutive or resets if broken, updates `users.xp_total += xp_earned`. Note: `submit_lesson` does NOT independently run `user.xp_total += xp_earned` to avoid double counting.

## Code Layout
### Backend Files
- `backend_app/backend/app/core/config/settings.py` (M1)
- `docker-compose.yml` (M1)
- `backend_app/backend/alembic/env.py` (M1)
- `backend_app/backend/app/modules/learning/service.py` (M1)
- `backend_app/backend/app/db/seeds.py` (M3)
- `backend_app/backend/scripts/seed_data.py` (M3)
- `backend_app/backend/tests/` (M4)

### Frontend Files
- `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` (M2)
- `app_hoc_tieng_anh/ios/Runner/Info.plist` (M2)
- `app_hoc_tieng_anh/lib/core/config/app_config.dart` (M2)
- `app_hoc_tieng_anh/lib/core/network/app_api.dart` (M2)
- `app_hoc_tieng_anh/lib/features/auth/...` (M2)
- `app_hoc_tieng_anh/lib/features/learning/data/learning_api_service.dart` (M2)
- `app_hoc_tieng_anh/lib/features/learning/data/learning_repository.dart` (M2)
- `app_hoc_tieng_anh/lib/features/learning/presentation/pages/learning_path_page.dart` (M2)
- `app_hoc_tieng_anh/lib/features/learning/presentation/pages/lesson_page.dart` (M2)
- `app_hoc_tieng_anh/test/` (M4)
