"""
Alembic migration — initial schema.

Tạo bằng lệnh (cần DB đang chạy):
    cd backend_app/backend
    alembic revision --autogenerate -m "initial_schema"
    alembic upgrade head

File này là template hướng dẫn — khi chạy autogenerate sẽ tự sinh code thật.
"""

# Nội dung file này sẽ được THAY THẾ bởi `alembic revision --autogenerate`.
# Chạy khi docker-compose up postgres đã healthy.

# ── Hướng dẫn chạy ────────────────────────────────────────────────────────────
#
# 1. Khởi động PostgreSQL:
#       docker compose up postgres -d
#
# 2. Copy .env.example → .env và điền DATABASE_URL:
#       DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/english_ai
#
# 3. Sinh migration:
#       cd backend_app/backend
#       poetry run alembic revision --autogenerate -m "initial_schema"
#
# 4. Chạy migration:
#       poetry run alembic upgrade head
#
# 5. Kiểm tra tables:
#       docker exec -it <postgres_container> psql -U postgres -d english_ai
#       \dt
#       => users, scans, scan_items, words
