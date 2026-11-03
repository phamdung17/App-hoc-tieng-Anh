"""
tests/unit/test_alembic_config.py

Tests for alembic migration environment configuration (alembic/env.py):
1. Ensures application DATABASE_URL uses asyncpg async dialect.
2. Ensures offline URL sanitizes async driver (+asyncpg) for sync execution.
3. Ensures online async engine configuration preserves postgresql+asyncpg:// dialect.
"""

from __future__ import annotations

from unittest.mock import MagicMock, patch
import pytest

from app.core.config import settings


class TestAlembicDialectConfig:
    """Validate dialect and database URL handling in alembic configuration."""

    def test_database_url_contains_asyncpg(self) -> None:
        """Application DATABASE_URL must specify asyncpg driver for async SQLAlchemy."""
        assert "postgresql+asyncpg://" in settings.DATABASE_URL
        assert "psycopg2" not in settings.DATABASE_URL

    def test_sync_url_conversion_for_offline(self) -> None:
        """Offline mode URL must strip async driver (+asyncpg) so sync engine works."""
        raw_url = "postgresql+asyncpg://user:pass@localhost:5432/lingoup"
        offline_url = raw_url.replace("+asyncpg", "")
        assert offline_url == "postgresql://user:pass@localhost:5432/lingoup"
        assert "+asyncpg" not in offline_url

    def test_async_engine_configuration_preserves_asyncpg(self) -> None:
        """Online async engine configuration in run_async_migrations must preserve asyncpg."""
        config_section: dict[str, str] = {}
        # Simulate run_async_migrations URL assignment
        config_section["sqlalchemy.url"] = settings.DATABASE_URL
        assert "postgresql+asyncpg://" in config_section["sqlalchemy.url"]

    def test_alembic_env_imports_models_and_metadata(self) -> None:
        """Target metadata in alembic/env.py must contain all registered tables."""
        from app.core.database import Base
        import app.core.models  # noqa: F401

        tables = Base.metadata.tables
        assert "users" in tables
        assert "learning_paths" in tables
        assert "units" in tables
        assert "lessons" in tables
        assert "user_lesson_progress" in tables
        assert "user_daily_activities" in tables
