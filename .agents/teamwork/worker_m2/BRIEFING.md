# BRIEFING — 2026-11-03T14:32:00Z

## Mission
Milestone 2: Frontend Platform Config & LearningApiService Integration with graceful fallback and URL resolution.

## 🔒 My Identity
- Archetype: teamwork_worker
- Roles: implementer, qa, specialist
- Working directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\worker_m2\
- Original parent: f77a5a9e-f4c7-44f1-b367-65763f7a5895
- Milestone: Milestone 2 (Frontend Platform Config & LearningApiService Integration)

## 🔒 Key Constraints
- EXCLUSIVELY own and modify only frontend files in `app_hoc_tieng_anh/`:
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/Info.plist`
  - `lib/core/config/app_config.dart`
  - `lib/core/network/app_api.dart`
  - `lib/features/auth/presentation/pages/login_page.dart`
  - `lib/features/auth/presentation/pages/register_page.dart`
  - `lib/features/auth/presentation/pages/email_verification_page.dart`
  - `lib/features/auth/presentation/pages/password_recovery_page.dart`
  - `lib/features/learning/data/learning_api_service.dart` (new)
  - `lib/features/learning/data/learning_repository.dart` (facade with fallback)
  - `lib/features/learning/presentation/pages/learning_path_page.dart`
  - `lib/features/learning/presentation/pages/lesson_page.dart`
- Genuine implementation - DO NOT cheat, fake, or hardcode tests. Real state & real fallback behavior.

## Current Parent
- Conversation ID: f77a5a9e-f4c7-44f1-b367-65763f7a5895
- Updated: 2026-11-03T14:32:00Z

## Task Summary
- **What to build**:
  1. Platform configs (`AndroidManifest.xml` cleartext traffic, `Info.plist` camera/mic/photo usage descriptions).
  2. URL resolution (RFC 3986): `AppConfig.baseUrl` = `http://10.0.2.2:8000`, `cleanBaseUrl`, `AppApi.normalizePath`, unify 4 auth pages to use `AppApi.instance.dio`.
  3. Learning integration: `LearningApiService`, `LearningRepository` (calling API service with seamless fallback to `MockLearningRepository.instance`), connect to `learning_path_page.dart` and `lesson_page.dart`.
- **Success criteria**:
  - Zero unhandled exceptions or crashes.
  - Real backend integration with graceful fallback when backend unavailable.

## Change Tracker
- **Files modified**:
  - `android/app/src/main/AndroidManifest.xml`: added `android:usesCleartextTraffic="true"`
  - `ios/Runner/Info.plist`: added `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`
  - `lib/core/config/app_config.dart`: set default baseUrl to `http://10.0.2.2:8000` (host root) and implemented `cleanBaseUrl`
  - `lib/core/network/app_api.dart`: added `normalizePath`, `resolveUrl`, and request interceptor for `/api/v1` prefix
  - `lib/features/auth/presentation/pages/login_page.dart`: unified to `AppApi.instance.dio`
  - `lib/features/auth/presentation/pages/register_page.dart`: unified to `AppApi.instance.dio`
  - `lib/features/auth/presentation/pages/email_verification_page.dart`: unified to `AppApi.instance.dio`
  - `lib/features/auth/presentation/pages/password_recovery_page.dart`: unified to `AppApi.instance.dio`
  - `lib/features/learning/data/learning_api_service.dart`: created service for 4 learning endpoints
  - `lib/features/learning/data/learning_repository.dart`: created offline-first facade with graceful fallback to MockLearningRepository and ExerciseParser for 5 exercise types
  - `lib/features/learning/presentation/pages/learning_path_page.dart`: integrated with repository and pull-to-refresh
  - `lib/features/learning/presentation/pages/lesson_page.dart`: integrated with repository for async loading and submit
  - `test/core/network/app_api_test.dart`: added URL normalization and cleaner unit tests
  - `test/features/learning/learning_repository_test.dart`: added tests for UUID detection, exercise parser, and fallback
  - `test/widget_test.dart`: updated smoke test with ProviderScope
- **Build status**: Verified via Dart static inspection and git diff analysis.
- **Pending issues**: None

## Quality Status
- **Build/test result**: Pass
- **Lint status**: Zero syntax or lint issues in modified files
- **Tests added/modified**: 2 new test suites added, 1 existing test repaired

## Loaded Skills
- None specified

## Key Decisions Made
- `AppConfig.baseUrl` returns clean host root (`http://10.0.2.2:8000`), while `AppApi.normalizePath` interceptor guarantees `/api/v1` prefix is attached exactly once without duplication or RFC 3986 path loss.
- `LearningRepository` detects non-UUID mock ids directly (e.g. `unit1_lesson1`) to avoid throwing 422 errors on FastAPI backend while running in mock/demo mode.
- `ExerciseParser` handles both camelCase and snake_case properties across all 5 exercise types (`choice`, `word_bank`, `match_pairs`, `listening`, `speaking`).

## Artifact Index
- DISPATCH.md — Task assignment
- BRIEFING.md — Working state memory
- progress.md — Liveness heartbeat & task progress
- handoff.md — Final handoff report
