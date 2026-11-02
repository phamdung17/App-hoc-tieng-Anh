"""
app/workers/main.py

ARQ background worker — xử lý các task bất đồng bộ:
  - delete_scan_assets  : xóa ảnh trên S3/R2 sau khi scan bị xóa
  - delete_user_assets  : dọn dẹp tất cả assets khi user xóa tài khoản

Chạy worker:
    arq app.workers.main.WorkerSettings

Hoặc qua Docker Compose service worker.
"""

from __future__ import annotations

import logging

from arq import cron
from arq.connections import RedisSettings

from app.core.config import settings

logger = logging.getLogger(__name__)


# ── Task Functions ────────────────────────────────────────────────────────────

async def delete_scan_assets(ctx: dict, scan_id: str, image_key: str) -> None:
    """
    Xóa ảnh scan trên S3/R2 sau khi Scan record bị xóa khỏi DB.

    Args:
        scan_id: UUID của scan (để log).
        image_key: Object key trong bucket scans-private.
    """
    from app.integrations.storage import StorageClient
    from app.integrations.storage.errors import StorageDeleteError

    storage = StorageClient()
    try:
        await storage.delete(image_key)
        logger.info("Deleted scan asset: scan_id=%s key=%s", scan_id, image_key)
    except StorageDeleteError as exc:
        logger.error(
            "Failed to delete scan asset: scan_id=%s key=%s error=%s",
            scan_id, image_key, exc,
        )
        raise  # ARQ sẽ retry theo cấu hình


async def delete_user_assets(ctx: dict, user_id: str) -> None:
    """
    Xóa tất cả ảnh scan của user sau khi tài khoản bị xóa.
    Dùng list_objects để tìm và xóa theo prefix scans/{user_id}/.

    NOTE: Hiện tại là stub — implement đầy đủ khi có StorageClient.list_objects().
    """
    logger.info(
        "TODO: delete_user_assets for user_id=%s — "
        "implement list_objects when needed",
        user_id,
    )


async def startup(ctx: dict) -> None:
    """ARQ worker startup — khởi tạo connections."""
    from app.core.redis_client import init_redis
    await init_redis()
    logger.info("ARQ worker started")


async def shutdown(ctx: dict) -> None:
    """ARQ worker shutdown — đóng connections."""
    from app.core.redis_client import close_redis
    await close_redis()
    logger.info("ARQ worker stopped")


# ── Worker Settings ───────────────────────────────────────────────────────────

class WorkerSettings:
    """Cấu hình ARQ worker."""

    functions = [
        delete_scan_assets,
        delete_user_assets,
    ]
    on_startup = startup
    on_shutdown = shutdown

    redis_settings = RedisSettings.from_dsn(settings.REDIS_URL)

    # Retry: 3 lần, delay tăng dần
    max_tries = 3
    job_timeout = 60  # giây

    # Log level
    log_results = True
