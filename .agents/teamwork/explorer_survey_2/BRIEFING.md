# BRIEFING — 2026-11-03T14:02:00Z

## Mission
Completed comprehensive read-only survey of Flutter frontend in app_hoc_tieng_anh (Android cleartext traffic, iOS hardware usage descriptions, RFC 3986 URL resolver & Dio client unification, and Learning feature integration with mock fallback).

## 🔒 My Identity
- Archetype: teamwork_explorer
- Roles: Explorer, Synthesizer
- Working directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\
- Original parent: f77a5a9e-f4c7-44f1-b367-65763f7a5895
- Milestone: Survey Phase - Frontend Flutter App (Completed)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Investigation limited to analysis, synthesis, and reporting

## Current Parent
- Conversation ID: f77a5a9e-f4c7-44f1-b367-65763f7a5895
- Updated: 2026-11-03T14:02:00Z

## Investigation State
- **Explored paths**:
  - `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml`
  - `app_hoc_tieng_anh/ios/Runner/Info.plist`
  - `app_hoc_tieng_anh/lib/core/config/app_config.dart`
  - `app_hoc_tieng_anh/lib/core/network/app_api.dart`
  - All 12 API call sites and Dio instance instantiations across `lib/`
  - `app_hoc_tieng_anh/lib/features/learning/` (presentation pages, domain models, mock repo)
  - `backend_app/backend/app/modules/learning/` (router, schemas, service, models)
  - `app_hoc_tieng_anh/test/widget_test.dart`
- **Key findings**:
  1. `AndroidManifest.xml` lacks `android:usesCleartextTraffic="true"` (blocks HTTP on Android 9+).
  2. `Info.plist` lacks camera, microphone, and photo library usage descriptions (iOS crash SIGABRT).
  3. Dio URL resolution: `baseUrl` with `/api/v1` plus `/api/v1/...` paths leads to duplicate `/api/v1/api/v1/...` in Dio's string concatenation, while Dart `Uri.resolve` strips base path on leading slash. Unifying Dio via `AppApi.normalizePath` and setting `baseUrl` to host root (`http://10.0.2.2:8000`) prevents 404s and duplication across all 12 call sites.
  4. Learning feature currently runs 100% in RAM via `MockLearningRepository`. Architecture defined for `LearningApiService` (singleton calling `/api/v1/learning/...`) + `LearningRepository` with automatic fallback to mock data on offline/error/empty scenarios, preventing all crashes.
  5. Test suite needs `ProviderScope` for smoke test, plus unit tests for `AppApi.normalizePath` and `LearningRepository` mock fallback.
- **Unexplored areas**: None for frontend survey scope.

## Key Decisions Made
- Outlined a 3-pillar bulletproof URL architecture (`cleanBaseUrl`, `normalizePath`, and Dio interceptor) that is immune to RFC 3986 path stripping and duplicate `/api/v1/api/v1` prefixes.
- Designed a two-layer Learning data architecture: `LearningApiService` (remote) and `LearningRepository` (facade with offline mock fallback and UUID/empty content safeguards).

## Artifact Index
- `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\DISPATCH.md` — Received instructions
- `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\BRIEFING.md` — Persistent memory
- `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\progress.md` — Liveness heartbeat
- `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\survey_frontend.md` — Full survey & architectural blueprint
- `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_2\handoff.md` — 5-component handoff report

