# DISPATCH — Explorer Static & Verification

You are teamwork_explorer assigned to Static Analysis, Linter & Project Quality Verification.
Your working directory is: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_static\
Authoritative user request: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md

## Objective
Run static analysis, linters, tests, and syntax/import checks on both Backend and Frontend WITHOUT modifying any source code. Check documentation vs reality.

## Specific Tasks
1. Backend Verification:
   - Check Python environment, dependencies (`requirements.txt`), syntax check / pyflakes / flake8 / mypy / ruff if present or compileall/ast check.
   - Run existing backend tests (`pytest` in `backend_app/` or `backend_app/backend/`) if configured, capture pass/fail/error output.
   - Check Alembic migration consistency (`alembic check` or inspection of versions vs models).
2. Frontend Verification:
   - Check Flutter/Dart environment, `pubspec.yaml`, dependencies.
   - Run `dart analyze` or `flutter analyze` or check syntax/imports if dart/flutter CLI is available.
   - Run `flutter test` if tests exist in `app_hoc_tieng_anh/test/`.
3. Project Structure & Quality Review:
   - Analyze existing documentation: `project_review.md`, `weekly_implementation_plan.md`, `docker-compose.yml`, `README.md`.
   - Check git status (`git status --short`) to confirm codebase is clean and identify any untracked or modified files.
   - Summarize code quality issues (lint errors, unhandled exceptions, dead code, deprecated methods).
4. Write a comprehensive report to `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_static\static_audit.md` and your `handoff.md`.

## 2026-11-03T12:29:28Z
Read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md and d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_static\DISPATCH.md.
Your working directory is d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_static\.
Run static checks, linters, syntax checks, pytest, flutter/dart analyze (if tools available) on backend (`backend_app/`) and frontend (`app_hoc_tieng_anh/`).
Review git status, docs (`project_review.md`, `weekly_implementation_plan.md`, `docker-compose.yml`, `README.md`).
IMPORTANT: DO NOT modify any code. Only read files and run diagnostic commands.
Produce your detailed report at `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_static\static_audit.md` and your `handoff.md`.
Communicate back via send_message when complete.
