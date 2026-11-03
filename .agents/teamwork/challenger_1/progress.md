# Progress Tracking — Challenger 1

Last visited: 2026-11-03T13:08:00Z

## Current Status
Completed empirical testing and stress-testing of all 5 assigned claims in `AUDIT_REPORT.md`.

## Task Breakdown & Status
- [x] Claim 1: Backend router endpoints count (empirical count: 27 active endpoints vs reported 22 in header; table lists all 27) and `submit_lesson` in `learning/service.py` not calling `record_activity` (100% confirmed, 0 usages in backend).
- [x] Claim 2: Frontend `app_config.dart` baseUrl (`http://10.0.2.2:8000/api/v1`) and Dio leading slash issue across all 19 call sites in `lib/` causing 100% 404 via RFC 3986 (100% confirmed empirically).
- [x] Claim 3: `MockLearningRepository` usage in `learning_path_page.dart` and `lesson_page.dart` (100% confirmed, zero backend learning API calls).
- [x] Claim 4: `VocabularyApiService` UI references (100% confirmed orphaned, 0 references outside its declaration).
- [x] Claim 5: Missing password reset endpoint in BE auth router (100% confirmed, FE calls `/auth/forgot-password` and `/auth/reset-password` which do not exist).
- [x] Verdict Formulation: **APPROVE** (with note on endpoint count correction 22 -> 27).
