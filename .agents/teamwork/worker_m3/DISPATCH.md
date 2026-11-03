## 2026-11-03T14:32:48Z

You are worker_m3, a teamwork_worker subagent.

Your Working Directory: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\worker_m3\
Original Request File: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md
Project Document: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\orchestrator\PROJECT.md
Survey Report: d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_1\survey_backend.md
Audit Report: d:\LapTrinhMoBa\do_an_moba\AUDIT_REPORT.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY INSTRUCTIONS:
1. First, read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\ORIGINAL_REQUEST.md.
2. Read d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_survey_1\survey_backend.md §3 for the exact Seed Data architecture and exercise JSONB structures.
3. Your scope is Milestone 3: Database Seed Data Script.
   You EXCLUSIVELY own and will create/modify:
   - `backend_app/backend/app/db/seeds.py`
   - `backend_app/backend/scripts/seed_data.py` (or a CLI entrypoint in seeds.py)

4. Specific tasks:
   a. Create the seed data script that populates:
      - 2 Learning Paths:
        * Path 1: "English Basics & Daily Communication" (Level A1), containing 3 Units:
          - Unit 1: "Greetings & Introductions" (order 1) -> Lessons with exercises.
          - Unit 2: "Food & Dining" (order 2) -> Lessons with exercises.
          - Unit 3: "At the Airport & Travel" (order 3) -> Lessons with exercises.
        * Path 2: "Elementary English for Work & Life" (Level A2), containing 2 Units:
          - Unit 1: "Office & Jobs" (order 1) -> Lessons with exercises.
          - Unit 2: "Hobbies & Daily Routine" (order 2) -> Lessons with exercises.
      - The lessons must include exercises covering all 5 interactive types matching the schema in `survey_backend.md §3.2`:
        * `choice`
        * `wordBank`
        * `matchPairs`
        * `listening`
        * `speaking`
      - 28+ Vocabulary Words across 4 topics (`greeting`, `food`, `travel`, `daily`) with:
        * `lemma` (unique lowercase string)
        * `ipa`
        * `pos`
        * `meaning_vi`
        * `example_en`
        * `example_vi`
        * `topic`
        * `is_seeded = True`
   b. Ensure Idempotency:
      - Use deterministic UUIDs (e.g., fixed UUID constants or `uuid.uuid5(uuid.NAMESPACE_DNS, ...)` based on stable keys) so running the script multiple times will NOT create duplicate records or violate unique constraints.
      - Use `INSERT ... ON CONFLICT DO NOTHING` or check for existence before inserting.
   c. Make the seed script runnable both:
      - As a library module: `async def seed_all(session: AsyncSession)`
      - As a standalone CLI: `if __name__ == "__main__": asyncio.run(main())` that can be run with `python -m app.db.seeds` or `python scripts/seed_data.py`.

5. Verify:
   - Run python `py_compile` on the created script(s).
   - Test importing the seed script and verifying data structures (e.g. `python -c "from app.db.seeds import SEED_PATHS, SEED_WORDS; print(len(SEED_PATHS), len(SEED_WORDS))"`).
6. Write a comprehensive `handoff.md` in your working directory with Observation, Logic Chain, Caveats, Conclusion, Verification Commands & Results.
7. Send a message to the orchestrator with your results.
