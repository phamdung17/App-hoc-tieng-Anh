## 2026-11-03T14:33:09Z
You are worker_m4, a teamwork_worker subagent.

Your Working Directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\worker_m4\
Original Request File: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md
Project Document: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\orchestrator\PROJECT.md
Survey Report: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_3\survey_testing.md
Audit Report: d:\LapTrinhMoBa\do_an_moba\AUDIT_REPORT.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY INSTRUCTIONS:
1. First, read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md.
2. Read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_3\survey_testing.md for the complete test designs and implementation code templates.
3. Your scope is Milestone 4: Automated Verification Test Suites (pytest & flutter test).
   You EXCLUSIVELY own:
   Backend test files:
   - `backend_app/backend/tests/conftest.py`
   - `backend_app/backend/tests/unit/test_settings.py`
   - `backend_app/backend/tests/unit/test_auth_router.py`
   - `backend_app/backend/tests/unit/test_alembic_config.py`
   - `backend_app/backend/tests/unit/test_learning_progress_integration.py`
   Frontend test files:
   - `app_hoc_tieng_anh/test/widget_test.dart`
   - `app_hoc_tieng_anh/test/core/network/app_api_url_resolver_test.dart`
   - `app_hoc_tieng_anh/test/features/learning/learning_api_service_test.dart`
   - `app_hoc_tieng_anh/test/features/learning/learning_fallback_test.dart`

4. Specific tasks:
   a. Create the Backend Pytest test suite:
      - `tests/conftest.py`: Setup environment variables fixture and async test client fixtures.
      - `tests/unit/test_settings.py`: Test that CORS_ORIGINS parses list, comma-separated string, JSON string, and rejects invalid data.
      - `tests/unit/test_auth_router.py`: Test auth router endpoints (mocking database/dependencies where appropriate).
      - `tests/unit/test_alembic_config.py`: Test alembic env configuration ensures asyncpg URL dialect.
      - `tests/unit/test_learning_progress_integration.py`: Test `submit_lesson` invokes `ProgressService.record_activity`, streak updates, and no double XP counting.
   b. Create the Frontend Flutter test suite:
      - `test/widget_test.dart`: Update to wrap `LingoUpApp` in `ProviderScope` and smoke test app initialization without crashing.
      - `test/core/network/app_api_url_resolver_test.dart`: Test `AppApi.normalizePath` ensuring `/api/v1` is added when missing, not duplicated when present, and preserves root authority.
      - `test/features/learning/learning_api_service_test.dart`: Test `LearningApiService` methods (paths, path detail, lesson detail, submit lesson).
      - `test/features/learning/learning_fallback_test.dart`: Test `LearningRepository` fallback to `MockLearningRepository` when backend is down/unreachable.
   c. Execute and Verify:
      - Run backend tests: `uv run pytest` or `python -m pytest` inside `backend_app/backend/`.
      - Run frontend tests: `flutter test` or `flutter.bat test` inside `app_hoc_tieng_anh/`.
      - Ensure 100% of newly added tests pass.

5. Write a comprehensive `handoff.md` in your working directory with Observation, Logic Chain, Caveats, Conclusion, and exact Verification Commands & Output logs.
6. Send a message to the orchestrator with your results.
