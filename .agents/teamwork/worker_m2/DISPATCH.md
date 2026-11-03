## 2026-11-03T14:11:05Z
You are worker_m2, a teamwork_worker subagent.

Your Working Directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\worker_m2\
Original Request File: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md
Project Document: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\orchestrator\PROJECT.md
Survey Report: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\survey_frontend.md
Audit Report: d:\LapTrinhMoBa\do_an_moba\AUDIT_REPORT.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY INSTRUCTIONS:
1. First, read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md.
2. Read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\survey_frontend.md for detailed blueprints and code snippets.
3. Your scope is Milestone 2: Frontend Platform Config & LearningApiService Integration.
   You EXCLUSIVELY own and will modify only frontend files in `app_hoc_tieng_anh/`:
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

4. Specific tasks:
   a. Platform configurations:
      - `android/app/src/main/AndroidManifest.xml`: Add `android:usesCleartextTraffic="true"` to `<application>`.
      - `ios/Runner/Info.plist`: Add `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription` with clear Vietnamese descriptions inside `<dict>`.
   b. URL resolution (RFC 3986):
      - In `lib/core/config/app_config.dart`: Set `baseUrl` to `'http://10.0.2.2:8000'` (host root) and provide `cleanBaseUrl` that strips any trailing `/api/v1` or `/`.
      - In `lib/core/network/app_api.dart`: Implement static `normalizePath(String path)` that ensures paths have exactly one `/api/v1` prefix (unless absolute or `/health`), and apply this in the request interceptor.
      - Refactor the 4 auth pages (`login_page.dart`, `register_page.dart`, `email_verification_page.dart`, `password_recovery_page.dart`) to use `AppApi.instance.dio` instead of ad-hoc Dio instances.
   c. Learning integration & safe mock fallback:
      - Create `lib/features/learning/data/learning_api_service.dart` with methods to fetch paths, path detail, lesson detail, and submit lesson using `AppApi.instance.dio`.
      - Create `lib/features/learning/data/learning_repository.dart` (or update learning data layer) which acts as a robust facade:
        * Tries to call `LearningApiService`.
        * If backend call succeeds and returns valid data, parse and return it.
        * If backend call fails (network error, timeout, 404, or invalid/empty data), gracefully fall back to `MockLearningRepository.instance` with zero crashes or unhandled exceptions.
      - Integrate into `lib/features/learning/presentation/pages/learning_path_page.dart` and `lesson_page.dart` so they load learning data via the repository, support pull-to-refresh, submit results to backend, and seamlessly work offline/online.

5. Run `dart analyze` or verification commands on the modified files in `app_hoc_tieng_anh/` to ensure no syntax errors or lint issues.
6. Write a comprehensive `handoff.md` in your working directory following the standard format (Observation, Logic Chain, Caveats, Conclusion, Verification Commands & Results).
7. Send a message to the orchestrator with your results.
