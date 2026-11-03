# Handoff Report — explorer_survey_2 (Frontend Flutter Survey)

## 1. Observation

1. **Android Cleartext Traffic (`AndroidManifest.xml`)**:
   - File: `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` (lines 5–8):
     ```xml
     <application
         android:label="LingoUp"
         android:name="${applicationName}"
         android:icon="@mipmap/ic_launcher">
     ```
     Attribute `android:usesCleartextTraffic="true"` is missing from `<application>`.
2. **iOS Hardware Usage Descriptions (`Info.plist`)**:
   - File: `app_hoc_tieng_anh/ios/Runner/Info.plist` (lines 4–69):
     No keys for `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, or `NSPhotoLibraryUsageDescription` exist in the `<dict>`.
3. **Base URL and Dio Path Resolution**:
   - File: `app_hoc_tieng_anh/lib/core/config/app_config.dart` (lines 22–25):
     ```dart
     static const String baseUrl = String.fromEnvironment(
       'API_BASE_URL',
       defaultValue: 'http://10.0.2.2:8000/api/v1',
     );
     ```
   - File: `app_hoc_tieng_anh/lib/core/network/app_api.dart` (lines 8–17):
     `AppApi` initializes `Dio` with `baseUrl: AppConfig.baseUrl`.
   - Inspection of Dio 5.11.1 internal URI resolution (`options.dart`, lines 662–677):
     ```dart
     Uri get uri {
       String url = path;
       if (!url.startsWith(RegExp(r'https?:'))) {
         url = baseUrl + url;
         ...
       }
       return Uri.parse(url).normalizePath();
     }
     ```
     When `baseUrl` has `/api/v1` and path has `/api/v1`, Dio concatenates to `.../api/v1/api/v1/...` (HTTP 404). Conversely, standard Dart `Uri.parse(baseUrl).resolve('/auth/login')` strips `/api/v1` according to RFC 3986 section 5.2.2 (HTTP 404).
   - Fragmentation: 4 auth pages create uncoordinated local `Dio` instances:
     - `LoginPage` (`login_page.dart`:31): `final _dio = Dio(...)`
     - `RegisterPage` (`register_page.dart`:27): `final _dio = Dio(...)`
     - `EmailVerificationPage` (`email_verification_page.dart`:34): `late final Dio _dio = Dio(...)`
     - `PasswordRecoveryPage` (`password_recovery_page.dart`:24): `late final Dio _dio = Dio(...)`
4. **Learning Feature Integration State**:
   - File: `app_hoc_tieng_anh/lib/features/learning/presentation/pages/learning_path_page.dart` (line 18, 166):
     `final _repository = MockLearningRepository.instance;`
     `final units = _repository.getUnits();`
   - File: `app_hoc_tieng_anh/lib/features/learning/presentation/pages/lesson_page.dart` (lines 54–56, 171–174):
     `_lessonDetail = MockLearningRepository.instance.getLessonDetail(widget.lessonId);`
     `MockLearningRepository.instance.completeLesson(widget.lessonId, _lessonDetail.xpReward);`
   - Neither page calls any backend network service.
   - Backend `backend_app/backend/app/modules/learning/` has 4 fully functional endpoints ready:
     `GET /api/v1/learning/paths`, `GET /api/v1/learning/paths/{id}`, `GET /api/v1/learning/lessons/{id}`, `POST /api/v1/learning/lessons/{id}/submit`.
5. **Frontend Test Suite**:
   - File: `app_hoc_tieng_anh/test/widget_test.dart` (lines 13–29):
     Standard Flutter template counter test searching for `'0'` and `Icons.add`, which fails when executed on `LingoUpApp`.

---

## 2. Logic Chain

1. **Android Cleartext Block (Observation 1 -> Impact -> Fix)**:
   - On Android API 28+, cleartext HTTP traffic is blocked by default.
   - Connecting to `http://10.0.2.2:8000` from Android emulator triggers `IOException: Cleartext HTTP traffic not permitted`.
   - Therefore, adding `android:usesCleartextTraffic="true"` to `<application>` in `AndroidManifest.xml` is necessary to permit local HTTP dev requests.
2. **iOS Privacy Violation Crash (Observation 2 -> Impact -> Fix)**:
   - iOS terminates processes (`SIGABRT`) when accessing camera (`image_picker`), photo gallery, or microphone without explanation strings in `Info.plist`.
   - LingoUp features AI object scan and pronunciation exercises.
   - Therefore, adding `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, and `NSPhotoLibraryUsageDescription` is mandatory to prevent app store rejection and runtime termination.
3. **URL Resolution & Dio Unification (Observation 3 -> Impact -> Fix)**:
   - If `AppConfig.baseUrl` is kept as host root (`http://10.0.2.2:8000`), endpoints need `/api/v1`.
   - If callers write either `/auth/login` or `/api/v1/learning/paths`, discrepancies cause either missing `/api/v1` or duplicate `/api/v1/api/v1`.
   - Adding a static normalizer `AppApi.normalizePath` guarantees path always has exactly one `/api/v1` prefix (preserving absolute URLs and `/health`).
   - Using this normalizer in `AppApi` request interceptor and replacing local `Dio` instances in the 4 auth pages with `AppApi.instance.dio` eliminates fragmentation and ensures consistent routing across 100% of network calls.
4. **Learning Feature Integration & Offline Fallback (Observation 4 -> Architecture)**:
   - Backend learning endpoints require authenticated requests and return structured JSON (units, lessons, exercises in JSONB `content_data`).
   - If network fails, backend is offline, database is not seeded, or user accesses a mock lesson ID, directly calling backend without fallback causes app crashes or blank screens.
   - Introducing `LearningApiService` (singleton calling endpoints) and `LearningRepository` (facade with try-catch and format checks) allows `LearningPathPage` and `LessonPage` to fetch real data when available while seamlessly falling back to `MockLearningRepository.instance` on any failure.
5. **Automated Verification (Observation 5 -> Test Strategy)**:
   - Fixing `widget_test.dart` by wrapping `LingoUpApp` in `ProviderScope` ensures smoke tests pass.
   - Adding unit tests for `AppApi.normalizePath` and `LearningRepository` mock fallback satisfies requirement R4.

---

## 3. Caveats

1. **Google Sign-In on Mobile**: The app contains `google_auth_service.dart` sending `id_token` to `/auth/social/google`, but native Firebase/Google services files (`google-services.json` on Android and `GoogleService-Info.plist` on iOS) are not present in the repository. Testing Google Sign-In requires standard email/password authentication or mock tokens unless Google credentials are provided.
2. **Voice Recognition in Speaking Exercises**: The speaking exercise widget currently simulates voice evaluation after a brief timer (`_speakingDone = true`). Real-time speech-to-text integration is planned for future milestones as noted in AUDIT_REPORT.

---

## 4. Conclusion

The Frontend Flutter app has an excellent UI/UX foundation (5 interactive exercise widgets, Duolingo-style learning path road, sound effects, scanner overlay), but is hindered by three configuration blockers (Android cleartext traffic, iOS usage descriptions, and Dio URL prefix resolution) and an unintegrated Learning feature.

Applying the 10-step actionable plan documented in `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\survey_frontend.md` will completely resolve all blockers, integrate the backend learning module with resilient zero-crash fallback, unify HTTP client communications, and achieve 100% test pass rate on `flutter test`.

---

## 5. Verification Method

1. **Verify Android Manifest**:
   - Inspect `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` to ensure `android:usesCleartextTraffic="true"` is present in `<application>`.
2. **Verify iOS Info.plist**:
   - Inspect `app_hoc_tieng_anh/ios/Runner/Info.plist` to ensure all 3 `NS*UsageDescription` keys are present.
3. **Verify URL Resolver & Test Execution**:
   - Run `flutter test` inside `app_hoc_tieng_anh/`.
   - Verify `test/core/network/app_api_test.dart` passes:
     - `normalizePath('/auth/login')` == `'/api/v1/auth/login'`
     - `normalizePath('/api/v1/learning/paths')` == `'/api/v1/learning/paths'`
     - `cleanBaseUrl('http://10.0.2.2:8000/api/v1/')` == `'http://10.0.2.2:8000'`
4. **Verify Learning Mock Fallback**:
   - Disconnect network or stop backend, launch app, navigate to Learning Path page: verify 3 units render from mock data without exception.
   - Start backend, navigate to Learning Path page: verify units load from backend.

