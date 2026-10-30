"""
app/main.py

Entry point của FastAPI application.
- Tạo app instance với lifespan context
- Đăng ký routers từ các modules
- Cấu hình CORS, middleware, exception handlers
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.redis_client import close_redis, init_redis

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """
    Lifecycle manager: chạy startup/shutdown logic.
    - Startup: log môi trường, khởi tạo Redis pool
    - Shutdown: đóng connection pools
    """
    logger.info(
        "🚀 Starting English AI Backend | env=%s | debug=%s",
        settings.APP_ENV,
        settings.DEBUG,
    )
    logger.info("🤖 AI Provider: Gemini API | model=%s", settings.GEMINI_MODEL)

    # Khởi tạo Redis pool
    await init_redis()

    yield

    # Graceful shutdown
    await close_redis()
    logger.info("👋 Shutting down English AI Backend")


def create_app() -> FastAPI:
    """Factory function — tạo và cấu hình FastAPI app."""

    app = FastAPI(
        title="English Learning AI — Backend API",
        description=(
            "REST API cho app học tiếng Anh với AI scan vật thể.\n\n"
            "AI Provider: **Google Gemini API** (thay thế YOLO-World container)."
        ),
        version="1.0.0",
        debug=settings.DEBUG,
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        lifespan=lifespan,
    )

    # ── CORS ──────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Routers ───────────────────────────────────────────────────────────
    from app.modules.auth.router import router as auth_router
    from app.modules.scan.router import router as scan_router

    app.include_router(auth_router, prefix=settings.API_V1_PREFIX)
    app.include_router(scan_router, prefix=settings.API_V1_PREFIX)

    # ── Health check ──────────────────────────────────────────────────────
    @app.get("/health", tags=["system"], summary="Health check")
    async def health() -> dict:
        return {
            "status": "ok",
            "env": settings.APP_ENV,
            "ai_provider": "gemini",
            "model": settings.GEMINI_MODEL,
        }

    return app


app = create_app()
