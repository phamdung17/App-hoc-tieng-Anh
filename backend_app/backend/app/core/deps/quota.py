"""
app/core/deps/quota.py

Redis-based quota tracking cho AI scan.

Chiến lược:
  - Key: "scan_quota:{user_id}:{YYYY-MM-DD}" (UTC date)
  - TTL: tự động expire lúc nửa đêm UTC hôm sau (tối đa ~48h)
  - Atomically increment trước → check sau: tránh race condition

Flow:
  1. INCR key → nhận count mới
  2. Nếu count == 1 (lần đầu trong ngày) → SET EXPIREAT đến nửa đêm UTC
  3. Nếu count > limit → decrement lại + raise QuotaExceededError
  4. Nếu count <= limit → cho phép tiếp tục

Quota chỉ bị tiêu thụ sau khi scan thành công (gọi commit_scan_quota).
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING

from fastapi import Depends, HTTPException, status

from app.core.config import settings

if TYPE_CHECKING:
    from redis.asyncio import Redis


# ── Redis dependency ─────────────────────────────────────────────────────────

async def get_redis() -> "Redis":
    """
    FastAPI dependency: trả Redis client.
    Redis pool được init trong lifespan của main.py.
    """
    from app.core.redis_client import redis_pool  # lazy import
    return redis_pool


# ── Quota helpers ─────────────────────────────────────────────────────────────

def _quota_key(user_id: uuid.UUID, date_str: str) -> str:
    """Tạo Redis key cho quota của user ngày hôm nay."""
    return f"scan_quota:{user_id}:{date_str}"


def _today_utc() -> str:
    """Trả về ngày hôm nay UTC dạng YYYY-MM-DD."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def _next_midnight_timestamp() -> int:
    """Unix timestamp của nửa đêm UTC ngày mai (thời điểm reset quota)."""
    now = datetime.now(timezone.utc)
    midnight_tomorrow = (now + timedelta(days=1)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    return int(midnight_tomorrow.timestamp())


def _next_midnight_iso() -> str:
    """ISO 8601 string của nửa đêm UTC ngày mai."""
    now = datetime.now(timezone.utc)
    midnight_tomorrow = (now + timedelta(days=1)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    return midnight_tomorrow.isoformat()


# ── Quota operations ──────────────────────────────────────────────────────────

async def check_scan_quota(
    user_id: uuid.UUID,
    redis: "Redis",
) -> tuple[int, int]:
    """
    Kiểm tra quota hiện tại của user MÀ KHÔNG increment.

    Returns:
        (used, remaining)
    """
    key = _quota_key(user_id, _today_utc())
    raw = await redis.get(key)
    used = int(raw) if raw else 0
    remaining = max(0, settings.SCAN_QUOTA_PER_USER_DAILY - used)
    return used, remaining


async def reserve_scan_quota(
    user_id: uuid.UUID,
    redis: "Redis",
) -> str:
    """
    Tạm giữ 1 lượt scan (increment). Gọi trước khi call Gemini.
    Nếu vượt limit → decrement lại + raise 429.

    Raises:
        HTTPException 429 SCAN_LIMIT_REACHED
    """
    key = _quota_key(user_id, _today_utc())
    limit = settings.SCAN_QUOTA_PER_USER_DAILY

    # Atomic increment
    count = await redis.incr(key)

    # Set TTL chỉ lần đầu trong ngày (count == 1)
    if count == 1:
        await redis.expireat(key, _next_midnight_timestamp())

    if count > limit:
        # Vượt quota → hoàn trả slot
        await redis.decr(key)
        used = limit
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "SCAN_LIMIT_REACHED",
                "used": used,
                "limit": limit,
                "remaining": 0,
                "reset_at": _next_midnight_iso(),
            },
        )
    return key


async def release_scan_quota(
    user_id: uuid.UUID,
    redis: "Redis",
    key: str | None = None,
) -> None:
    """
    Hoàn trả 1 lượt scan đã reserve khi scan thất bại.
    Gọi trong except block của scan service khi Gemini lỗi / ảnh invalid.
    """
    # Dùng key đã reserve để scan chạy qua nửa đêm không đụng quota ngày mới.
    key = key or _quota_key(user_id, _today_utc())
    # Đảm bảo không xuống dưới 0
    current = await redis.get(key)
    if current and int(current) > 0:
        await redis.decr(key)


async def get_quota_info(
    user_id: uuid.UUID,
    redis: "Redis",
) -> dict:
    """
    Trả về dict quota info cho GET /scans/quota endpoint.
    """
    used, remaining = await check_scan_quota(user_id, redis)
    limit = settings.SCAN_QUOTA_PER_USER_DAILY
    return {
        "used": used,
        "limit": limit,
        "remaining": remaining,
        "reset_at": _next_midnight_iso(),
    }
