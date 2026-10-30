"""
alembic/env.py

Cấu hình Alembic migration environment.
- Đọc DATABASE_URL từ settings (không hardcode trong alembic.ini)
- Hỗ trợ async engine (asyncpg)
- Autogenerate nhận diện tất cả models từ app.core.models
"""

from __future__ import annotations

import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

# Import Base và tất cả models để autogenerate hoạt động
from app.core.database import Base
import app.core.models  # noqa: F401 — side effect: register all models

from app.core.config import settings

# ── Alembic Config ────────────────────────────────────────────────────────────

config = context.config

# Đọc logging config từ alembic.ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Target metadata cho autogenerate
target_metadata = Base.metadata

# Override URL từ settings (không dùng URL trong alembic.ini)
# Thay asyncpg → psycopg2 cho alembic sync mode
_sync_url = settings.DATABASE_URL.replace(
    "postgresql+asyncpg://", "postgresql+psycopg2://"
)


# ── Offline mode ──────────────────────────────────────────────────────────────

def run_migrations_offline() -> None:
    """
    Chạy migrations trong 'offline' mode — sinh SQL scripts mà không kết nối DB.
    Dùng để review DDL trước khi apply vào production.
    """
    context.configure(
        url=_sync_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


# ── Online mode (async) ───────────────────────────────────────────────────────

def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Chạy migration với async engine."""
    # Tạo async engine từ sync URL (alembic chưa hỗ trợ native async)
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = _sync_url

    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Chạy migration khi kết nối DB khả dụng."""
    asyncio.run(run_async_migrations())


# ── Entry point ───────────────────────────────────────────────────────────────

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
