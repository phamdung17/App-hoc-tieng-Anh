"""
app/core/redis_client.py

Redis async client pool — khởi tạo trong lifespan của main.py.
"""

from __future__ import annotations

import logging

import redis.asyncio as aioredis

from app.core.config import settings

logger = logging.getLogger(__name__)

# Module-level pool — được gán trong lifespan startup
redis_pool: aioredis.Redis | None = None


async def init_redis() -> aioredis.Redis:
    """Khởi tạo Redis connection pool. Gọi từ lifespan startup."""
    global redis_pool
    redis_pool = aioredis.from_url(
        settings.REDIS_URL,
        encoding="utf-8",
        decode_responses=True,
        max_connections=20,
    )
    # Kiểm tra kết nối
    await redis_pool.ping()
    logger.info("✅ Redis connected: %s", settings.REDIS_URL)
    return redis_pool


async def close_redis() -> None:
    """Đóng Redis pool. Gọi từ lifespan shutdown."""
    global redis_pool
    if redis_pool:
        await redis_pool.aclose()
        redis_pool = None
        logger.info("Redis connection closed")
