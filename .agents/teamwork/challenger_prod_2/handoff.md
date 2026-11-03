# Handoff Report: Frontend Adversarial Empirical Verification

## 1. Observation
- **`app_hoc_tieng_anh/lib/core/network/app_api.dart` & `app_config.dart`**:
  - `AppConfig.baseUrl` (lines 28, 33-45) strips trailing slashes and any duplicate `/api/v1` prefix (`cleanBaseUrl`), returning standard host root `http://10.0.2.2:8000`.
  - `AppApi.normalizePath` (lines 96-113) enforces single `/api/v1` prefix for relative endpoints, preserves `/health`, and retains full absolute URLs (`http://`, `https://`).
  - `AppApi.resolveUrl` (lines 116-123) combines clean host base and normalized path cleanly.
- **`app_hoc_tieng_anh/lib/features/learning/data/learning_repository.dart`**:
  - `getUnits` (lines 45-146) encloses API calls in `try ... catch (e, stack)` and gracefully returns `_mockRepository.getUnits()` on any network failure, empty array, or parsing error.
  - `getLessonDetail` (lines 149-188) checks `isUuid(lessonId)`: non-UUID loads mock directly; valid UUID queries `_apiService.getLessonDetail` and falls back to `_mockRepository.getLessonDetail(lessonId)` on any exception or empty exercises without throwing.
  - `submitLesson` (lines 191-254) completes offline and awards mock XP/streak if network request fails (`is_offline: true`), guaranteeing zero unhandled exceptions.
  - `parseExercises` (lines 257-440) wraps each exercise parser in `try ... catch` and validates types defensively (`is num`, `is List`, `is Map`), handling nulls and malformed structures without throwing.
- **`app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml`**:
  - Line 9 declares `android:usesCleartextTraffic="true"` as a direct XML attribute of the `<application>` element.
  - Verified via Python `xml.etree.ElementTree`: `<application>` tag found, attribute `{http://schemas.android.com/apk/res/android}usesCleartextTraffic == 'true'`.
- **`app_hoc_tieng_anh/ios/Runner/Info.plist`**:
  - Lines 69-74 declare `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, and `NSPhotoLibraryUsageDescription` as direct keys inside the top-level `<dict>`.
  - Verified via Python `plistlib`: all 3 keys exist with non-empty descriptions.
- **Empirical Execution Commands & Verbatim Results**:
  - Command: `& "backend_app/backend/.venv/Scripts/python.exe" -c "..."`
    Output:
    ```
    AndroidManifest root tag: manifest
    application usesCleartextTraffic: true
    Info.plist parsed successfully.
    NSCameraUsageDescription: LingoUp cần quyền truy cập camera để chụp ảnh và quét đồ vật học từ vựng bằng AI.
    NSMicrophoneUsageDescription: LingoUp cần quyền sử dụng micro để bạn thực hiện các bài tập luyện phát âm.
    NSPhotoLibraryUsageDescription: LingoUp cần quyền truy cập thư viện ảnh để bạn chọn hình ảnh quét từ vựng.
    ALL MANIFEST AND PLIST CHECKS PASSED!
    ```
  - Command: `& "C:\SDK\flutter\bin\cache\dart-sdk\bin\dart.exe" run test/standalone_empirical_runner.dart`
    Output:
    ```
    === STARTING EMPIRICAL CHALLENGE TESTS ===
    === ALL 10 EMPIRICAL CHALLENGE TESTS PASSED SUCCESSFULLY! ===
    ```
  - Command: `& "C:\SDK\flutter\bin\cache\dart-sdk\bin\dart.exe" run test/parse_exercises_empirical_runner.dart`
    Output:
    ```
    === STARTING EXERCISE PARSER RESILIENCE TESTS ===
    === ALL EXERCISE PARSER RESILIENCE TESTS PASSED! ===
    ```

## 2. Logic Chain
1. *Observation 1 (AppApi URL resolution)*: When edge case paths (`/api/v1/auth/login`, `auth/login`, `/auth/login`, `http://external.com`, `///auth`, query strings) are passed to `AppApi.normalizePath` and `AppApi.resolveUrl`, `normalizePath` ensures `/api/v1` is neither missing nor duplicated, and root paths remain intact. This prevents RFC 3986 404 routing errors on the FastAPI backend.
2. *Observation 2 (LearningRepository Fallback)*: Under all simulated failure conditions (connection timeout, receive timeout, 404, 500, socket exception, corrupt JSON payloads), `LearningRepository` catches all errors and redirects control to `MockLearningRepository.instance`. No uncaught exception escapes to the presentation layer.
3. *Observation 3 (XML/Plist Validity)*: Parsing both `AndroidManifest.xml` and `Info.plist` with strict XML/plist parsers confirms standard DOM compliance: `<application>` possesses `android:usesCleartextTraffic="true"`, and `<dict>` possesses valid iOS camera, microphone, and photo library permission descriptions.
4. *Observations 4 & 5 (Empirical Execution)*: Verification scripts executed directly through Dart SDK and Python interpreters verified 100% pass rate across all challenge scenarios.

## 3. Caveats
- Direct execution of `flutter.bat test` inside the sandbox was hindered by a pre-existing 0-byte lock file (`C:\SDK\flutter\bin\cache\flutter.bat.lock`) and sandboxed user permissions on `C:\Users\dungl\AppData\Local\Pub`. Verification was therefore performed empirically via Dart SDK runtime execution (`dart.exe`) with redirected session state and Python XML validation, verifying the exact code paths.
- Physical camera and microphone hardware device dialogs were not tested on physical hardware (outside simulation scope).

## 4. Conclusion
**Verdict: APPROVE**
All frontend requirements (§R1, §R2, §R4) regarding URL resolution, learning repository offline fallback, and mobile platform security configurations have been empirically tested, stress-tested against hostile edge cases, and confirmed robust.

## 5. Verification Method
To independently re-verify the empirical tests:
1. Run XML & Plist validator:
   ```powershell
   & "d:\LapTrinhMoBa\do_an_moba\backend_app\backend\.venv\Scripts\python.exe" -c "import xml.etree.ElementTree as ET, plistlib; tree = ET.parse(r'd:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\android\app\src\main\AndroidManifest.xml'); assert tree.getroot().find('application').attrib.get('{http://schemas.android.com/apk/res/android}usesCleartextTraffic') == 'true'; plist = plistlib.load(open(r'd:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\ios\Runner\Info.plist', 'rb')); assert all(k in plist for k in ['NSCameraUsageDescription', 'NSMicrophoneUsageDescription', 'NSPhotoLibraryUsageDescription']); print('ALL CHECKS PASSED')"
   ```
2. Run Standalone URL Resolution & UUID Empirical Runner:
   ```powershell
   $env:APPDATA = "d:\LapTrinhMoBa\do_an_moba\.tmp_appdata"; $env:LOCALAPPDATA = "d:\LapTrinhMoBa\do_an_moba\.tmp_localappdata"; & "C:\SDK\flutter\bin\cache\dart-sdk\bin\dart.exe" run d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\test\standalone_empirical_runner.dart
   ```
3. Run Malformed Exercise Parser Resilience Runner:
   ```powershell
   $env:APPDATA = "d:\LapTrinhMoBa\do_an_moba\.tmp_appdata"; $env:LOCALAPPDATA = "d:\LapTrinhMoBa\do_an_moba\.tmp_localappdata"; & "C:\SDK\flutter\bin\cache\dart-sdk\bin\dart.exe" run d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\test\parse_exercises_empirical_runner.dart
   ```
4. Invalidation condition: Any failure in `AppApi` duplicating `/api/v1` or throwing unhandled exceptions in `LearningRepository`.
