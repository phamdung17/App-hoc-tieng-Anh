"""
app/core/database.py

Async SQLAlchemy engine, session factory, và base dependency.
Dùng asyncpg driver với PostgreSQL.
"""

from __future__ import annotations

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

# ── Engine ────────────────────────────────────────────────────────────────────

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,   # Kiểm tra connection còn sống trước khi dùng
    echo=settings.DEBUG,  # Log SQL queries trong dev
)

# ── Session Factory ───────────────────────────────────────────────────────────

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Tránh lazy-load sau commit
    autoflush=False,
    autocommit=False,
)


# ── Base Class ────────────────────────────────────────────────────────────────

class Base(DeclarativeBase):
    """Base declarative class cho tất cả SQLAlchemy models."""
    pass


# ── FastAPI Dependency ────────────────────────────────────────────────────────

async def get_db() -> AsyncIterator[AsyncSession]:
    """
    FastAPI dependency: cung cấp async DB session per request.
    Tự động commit khi không có exception, rollback khi có exception.

    Usage:
        @router.get("/items")
        async def list_items(db: AsyncSession = Depends(get_db)):
            ...
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
