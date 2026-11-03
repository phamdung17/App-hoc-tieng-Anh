# Handoff Report — Frontend Flutter Audit

**Agent**: `explorer_frontend`  
**Working Directory**: `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_frontend\`  
**Target Codebase**: `d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\`  
**Date**: 2026-11-03T12:48:00Z  
**Type**: Hard Handoff (Investigation Complete)

---

## 1. Observation

1. **Flutter Dependencies & Architecture**:
   - `app_hoc_tieng_anh/pubspec.yaml` lines 38-72: includes `flutter_riverpod: ^2.5.1`, `go_router: ^14.2.7`, `dio: ^5.7.0`, `flutter_secure_storage: ^9.2.2`, `image_picker: ^1.1.2`, `google_sign_in: ^6.2.2`, `audioplayers: ^6.8.1`, `flutter_local_notifications: ^22.3.3`.
   - Entry point: `lib/main.dart` lines 5-7 runs `runApp(buildApp())` defined in `lib/app/app.dart` line 23 (`const ProviderScope(child: LingoUpApp())`).
   - Router: `lib/app/router.dart` lines 34-55 defines `AppRoutes` constants (`/welcome`, `/survey`, `/auth`, `/register`, `/verify-email`, `/forgot-password`, `/reset-password`, `/flashcards`, `/home`, `/scan`, `/scan-result`, `/word/:id`, `/lesson/:id`, `/lesson-result`).
   - Shell: `lib/app/router.dart` lines 212-236 defines `ShellRoute` with `MainShell` containing 4 tabs (Lộ trình, Từ vựng, Ôn tập, Hồ sơ) and center camera FAB pointing to `/scan`.

2. **Network Layer & API Clients**:
   - `lib/core/network/app_api.dart`:
     - Line 11: `baseUrl = AppConfig.baseUrl` (defaults in `lib/core/config/app_config.dart` line 24 to `'http://10.0.2.2:8000/api/v1'`).
     - Line 20-30: Interceptor attaches `Authorization: Bearer <access_token>`.
     - Line 32-72: `QueuedInterceptorsWrapper` on 401 calls `POST /auth/refresh` with `{'refresh_token': token}` and retries request.
   - `lib/features/scan/data/scan_api_service.dart`:
     - Line 26: `GET /scans/quota`
     - Line 31-36: `POST /scans` with `FormData` (`image: MultipartFile.fromFile(path)`)
     - Line 54-57: `PATCH /scans/items/$itemId/saved` with `{'is_saved': saved}`
     - Line 61: `GET /scans/saved-words`
   - `lib/features/vocabulary/data/vocabulary_api_service.dart`:
     - Lines 26, 48, 56, 64: `GET /vocab`, `GET /vocab/topics`, `GET /vocab/$wordId`, `GET /vocab/lemma/$lemma`.
     - Grep search `grep_search VocabularyApiService` returns only `lib/features/vocabulary/data/vocabulary_api_service.dart` itself. No screens call this service.
   - `lib/core/auth/google_auth_service.dart` line 46 calls `POST /auth/social/google`.
   - Fragmented Dio instances: `login_page.dart` (line 31), `register_page.dart` (line 27), `email_verification_page.dart` (line 34), `password_recovery_page.dart` (line 24) all instantiate `Dio(...)` privately instead of using `AppApi.instance.dio`.

3. **Screen-to-Backend Connection State**:
   - **Real API connected**:
     - `LoginPage`: `POST /auth/login` (lines 68-75), `GoogleAuthService.signIn` (line 605).
     - `RegisterPage`: `POST /auth/register` (line 58).
     - `EmailVerificationPage`: `POST /auth/verify-email` (line 63) and `POST /auth/resend-verify` (line 92).
     - `ScanCameraPage`: `GET /scans/quota` (line 45), `ScanApiService.scanImage` (line 72).
     - `ScanResultPage`: `ScanApiService.setSaved` (line 48).
     - `VocabularyPage`: `GET /scans/saved-words` (line 20).
     - `VocabularyDetailPage`: `GET /scans/saved-words` (line 33), `ScanApiService.setSaved` (line 137).
     - `ReviewPage`: `GET /scans/saved-words` (line 34).
     - `ProfilePage`: `GET /auth/me` (line 40), `GET /scans/quota` (line 44), `GET /scans/saved-words` (line 48).
   - **Mock / Disconnected screens**:
     - `LearningPathPage`: `lib/features/learning/presentation/pages/learning_path_page.dart` line 18: `final _repository = MockLearningRepository.instance;`
     - `LessonPage`: `lib/features/learning/presentation/pages/lesson_page.dart` line 54: `MockLearningRepository.instance.getLessonDetail(widget.lessonId);`
     - `LessonResultPage`: `lib/features/learning/presentation/pages/lesson_page.dart` line 171: `MockLearningRepository.instance.completeLesson(...)`; does not call `POST /learning/lessons/{id}/submit`.
     - `PracticeHubPage`: lines 23-46 hardcode `_dueTodayCount = 7` and 3 dummy wrong answers; lines 97, 113, 128 show "Coming Soon" snackbars.
     - `PasswordRecoveryPage`: lines 44-48 calls `POST /auth/forgot-password` / `POST /auth/reset-password`; backend `app/modules/auth/router.py` does not have these routes.
     - `Progress`: `lib/features/progress/` has only empty directories with `.gitkeep` and `README.md`. No UI exists for backend `/progress/summary` or `/progress/calendar`.

4. **Platform & Permissions**:
   - `android/app/src/main/AndroidManifest.xml` line 5: `<application>` does not have `android:usesCleartextTraffic="true"`.
   - `android/app/google-services.json` does not exist (`Test-Path` returned False).
   - `ios/Runner/GoogleService-Info.plist` does not exist (`Test-Path` returned False).
   - `ios/Runner/Info.plist` lacks `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `NSMicrophoneUsageDescription`.

5. **Test Suite**:
   - `test/widget_test.dart` lines 15-27 pumps `const LingoUpApp()` directly without `ProviderScope`, and asserts on counter text `'0'` and `Icons.add`.

---

## 2. Logic Chain

1. **Finding on AI Scan & Vocabulary**:
   - Observations 1, 2, and 3 confirm that `ScanCameraPage`, `ScanResultPage`, `VocabularyPage`, `VocabularyDetailPage`, and `ReviewPage` actively invoke endpoints implemented in backend `scan` router (`/scans`, `/scans/quota`, `/scans/items/{id}/saved`, `/scans/saved-words`).
   - Therefore, the AI Scan -> Save Word -> View Word Detail -> Practice Flashcards user flow is genuinely integrated end-to-end.

2. **Finding on Learning Module**:
   - Observation 3 confirms `LearningPathPage`, `LessonPage`, and `LessonResultPage` rely exclusively on in-memory `MockLearningRepository.instance`. Backend `app/modules/learning/router.py` provides `/learning/paths`, `/learning/paths/{id}`, `/learning/lessons/{id}`, and `/learning/lessons/{id}/submit`, but no Frontend service connects to them.
   - Therefore, the learning feature operates completely disconnected from the database and backend.

3. **Finding on Technical Debt & Platform Risks**:
   - Android 9+ enforces cleartext traffic restrictions by default. Because `app_config.dart` defaults to `http://10.0.2.2:8000` and `AndroidManifest.xml` lacks `android:usesCleartextTraffic="true"`, HTTP network requests will fail in Android emulators and devices unless configured.
   - iOS crashes immediately when invoking camera/photo picker without `Info.plist` usage descriptions.
   - Running `flutter test` fails instantly because `widget_test.dart` pumps `LingoUpApp` without `ProviderScope` and expects an obsolete counter widget.

---

## 3. Caveats

- Testing against a live Android device or emulator with a running backend server was not performed due to the read-only audit scope and headless environment.
- Native Google Sign-In requires active Google Play Services and registered SHA-1 keys in Firebase Console, which cannot be tested in a headless environment.
- No source code or configuration files were modified.

---

## 4. Conclusion

The Frontend Flutter application demonstrates high-quality UI/UX design, excellent interactive exercises, and a working core integration with the FastAPI Gemini AI scan service and saved vocabulary. However, it exhibits a major architectural gap: the entire learning progression system (`features/learning/`) is mocked and disconnected from the Backend API, several backend capabilities (`vocab` catalog, `progress` calendar/summary, `users` profile edit/delete) are not utilized in the UI, and key platform configurations (`usesCleartextTraffic`, iOS camera permissions, unit test suite) require remediation before graduation defense.

Detailed audit report written to:
`d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_frontend\frontend_audit.md`.

---

## 5. Verification Method

To independently verify the observations:
1. Verify presence and contents of the audit report:
   `Get-Content d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_frontend\frontend_audit.md`
2. Check `MockLearningRepository` usage in learning:
   `Select-String -Path "d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\lib\features\learning\**\*.dart" -Pattern "MockLearningRepository"`
3. Check `VocabularyApiService` references:
   `Select-String -Path "d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\lib\**\*.dart" -Pattern "VocabularyApiService"`
4. Check `AndroidManifest.xml` for cleartext flag:
   `Select-String -Path "d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\android\app\src\main\AndroidManifest.xml" -Pattern "usesCleartextTraffic"`
5. Check `test/widget_test.dart` failure expectation:
   Inspect lines 13-28 in `d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\test\widget_test.dart`.
