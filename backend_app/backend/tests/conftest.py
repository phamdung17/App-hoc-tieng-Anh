"""
backend_app/backend/tests/conftest.py

Global Pytest fixtures and environment configuration:
1. Setup mock environment variables before importing any app modules.
2. Windows environment socketpair sandbox-safety patch with IOCP threadpool wakeup.
3. Mock Redis initialization to avoid connecting to external Redis server.
4. Provide mock AsyncSession fixture for database isolation.
5. Provide ASGI AsyncClient fixtures for endpoint integration testing.
"""

from __future__ import annotations

import asyncio
import os
import sys
import uuid
from collections.abc import AsyncIterator
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

# ── 1. Setup mock environment variables before any app imports ────────────────
os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://mock_user:mock_pass@localhost:5432/mock_db")
os.environ.setdefault("JWT_SECRET_KEY", "mock-jwt-secret-key-that-is-at-least-32-chars-long-123456")
os.environ.setdefault("STORAGE_ENDPOINT", "http://localhost:9000")
os.environ.setdefault("STORAGE_ACCESS_KEY", "mock_minio_key")
os.environ.setdefault("STORAGE_SECRET_KEY", "mock_minio_secret")
os.environ.setdefault("STORAGE_BUCKET_PRIVATE", "scans-private-test")
os.environ.setdefault("STORAGE_BUCKET_PUBLIC", "content-public-test")
os.environ.setdefault("GEMINI_API_KEY", "AIzaSyMockApiKeyForTestOnly123456789")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/15")
os.environ.setdefault("CORS_ORIGINS", "http://localhost:3000,http://localhost:8000")

# ── 2. Windows socketpair sandbox compatibility patch ──────────────────────────
# In restricted Windows sandbox environments, connecting to loopback 127.0.0.1
# in socket.socketpair() triggers [WinError 10013]. We replace the self-pipe
# socketpair with IOCP completion status notifications so asyncio and threadpool
# workers operate seamlessly without requiring TCP network sockets.
if sys.platform == "win32":
    try:
        import _overlapped
        import asyncio.proactor_events
        import asyncio.windows_events

        def _safe_make_self_pipe(self):
            self._ssock = MagicMock()
            self._csock = MagicMock()
            self._csock.fileno.return_value = -1
            self._internal_fds += 1

        def _safe_close_self_pipe(self):
            self._ssock = None
            self._csock = None

        def _safe_loop_self_reading(self, f=None):
            pass

        def _wake_proactor(self):
            try:
                _overlapped.PostQueuedCompletionStatus(self._proactor._iocp, 0, 0, 0)
            except Exception:
                pass

        orig_poll = asyncio.windows_events.IocpProactor._poll

        def _safe_poll(self, timeout=None):
            try:
                return orig_poll(self, timeout)
            except OSError as e:
                if getattr(e, "winerror", None) == 0:
                    return
                raise

        asyncio.proactor_events.BaseProactorEventLoop._make_self_pipe = _safe_make_self_pipe
        asyncio.proactor_events.BaseProactorEventLoop._close_self_pipe = _safe_close_self_pipe
        asyncio.proactor_events.BaseProactorEventLoop._loop_self_reading = _safe_loop_self_reading
        asyncio.proactor_events.BaseProactorEventLoop._write_to_self = _wake_proactor
        asyncio.windows_events.IocpProactor._poll = _safe_poll
    except Exception:
        pass

# ── 3. Mock Redis startup/shutdown in FastAPI lifespan ─────────────────────────
patch("app.core.redis_client.init_redis", new_callable=AsyncMock).start()
patch("app.core.redis_client.close_redis", new_callable=AsyncMock).start()


@pytest.fixture(scope="session")
def anyio_backend() -> str:
    return "asyncio"


@pytest_asyncio.fixture
async def mock_db_session() -> AsyncIterator[AsyncMock]:
    """Mock SQLAlchemy AsyncSession for service tests without real database."""
    session = AsyncMock()
    session.execute = AsyncMock()
    session.add = MagicMock()
    session.flush = AsyncMock()
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    yield session


@pytest_asyncio.fixture
async def test_client() -> AsyncIterator[AsyncClient]:
    """AsyncClient using ASGITransport connected directly to the FastAPI app."""
    from app.main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        yield client
