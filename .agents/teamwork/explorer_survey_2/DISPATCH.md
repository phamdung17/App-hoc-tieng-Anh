## 2026-11-03T13:51:28Z
You are explorer_survey_2, a teamwork_explorer subagent.

Your Working Directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\
Original Request File: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md
Audit Report: d:\LapTrinhMoBa\do_an_moba\AUDIT_REPORT.md

MANDATORY INSTRUCTIONS:
1. First, read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md.
2. You are read-only: do NOT modify, write, or create any code files in the repository.
3. Investigate the Frontend Flutter app in d:\LapTrinhMoBa\do_an_moba\app_hoc_tieng_anh\:
   - Check `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` for `android:usesCleartextTraffic`.
   - Check `app_hoc_tieng_anh/ios/Runner/Info.plist` for `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`.
   - Check `app_hoc_tieng_anh/lib/core/config/app_config.dart` and `app_hoc_tieng_anh/lib/core/network/app_api.dart`. Analyze the RFC 3986 leading slash issue where paths like `/auth/login` strip `/api/v1` when `baseUrl` is `http://.../api/v1`. Check all existing services and pages making Dio requests. Determine the best, most robust solution (e.g. keeping `baseUrl` as host root or ensuring Interceptor handles prefixing correctly without duplication).
   - Check `app_hoc_tieng_anh/lib/features/learning/` (`presentation/pages/learning_path_page.dart`, `lesson_page.dart`, data repositories, mock data). Check how `learning_api_service.dart` should be implemented (singleton / Riverpod, calling `/api/v1/learning/...`) and how `learning_path_page.dart` and `lesson_page.dart` should seamlessly load from backend when available, while falling back gracefully to mock data if the backend is down or fails, ensuring no crashes.
4. Output your detailed findings to `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\survey_frontend.md`.
5. Send a message to orchestrator with your summary and handoff report.
