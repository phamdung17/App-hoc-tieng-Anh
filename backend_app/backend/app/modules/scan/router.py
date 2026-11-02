"""
app/modules/scan/router.py

FastAPI router cho scan module.
Endpoints:
  - GET  /scans/quota  : lượt scan còn lại hôm nay
  - POST /scans        : tạo scan mới từ ảnh upload
  - GET  /scans        : lịch sử scan (cursor-based pagination)
  - GET  /scans/{id}   : chi tiết một scan
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy import select

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps.auth import get_current_user, require_ai_user
from app.core.models.scan import Scan, ScanItem
from app.core.deps.quota import get_quota_info, get_redis, release_scan_quota, reserve_scan_quota
from app.core.models.user import User

from .errors import (
    AITemporarilyUnavailableError,
    ImageRejectedError,
    InvalidImageError,
    ScanFailedError,
)
from .schemas import (
    QuotaResponse,
    SaveScanItemRequest,
    SavedWordResponse,
    ScanResponse,
)
from .service import ScanService

router = APIRouter(prefix="/scans", tags=["scan"])


@router.get("/saved-words", response_model=list[SavedWordResponse])
async def get_saved_words(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[SavedWordResponse]:
    result = await db.execute(
        select(ScanItem)
        .join(Scan, Scan.id == ScanItem.scan_id)
        .where(Scan.user_id == current_user.id, ScanItem.is_saved.is_(True))
        .order_by(ScanItem.created_at.desc())
    )
    return [SavedWordResponse.model_validate(row) for row in result.scalars()]


@router.patch("/items/{item_id}/saved", response_model=SavedWordResponse)
async def set_saved_word(
    item_id: uuid.UUID,
    body: SaveScanItemRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SavedWordResponse:
    result = await db.execute(
        select(ScanItem)
        .join(Scan, Scan.id == ScanItem.scan_id)
        .where(ScanItem.id == item_id, Scan.user_id == current_user.id)
    )
    item = result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Saved word not found")
    item.is_saved = body.is_saved
    await db.commit()
    await db.refresh(item)
    return SavedWordResponse.model_validate(item)

# ── Dependency helpers ────────────────────────────────────────────────────────

def get_scan_service(db: AsyncSession = Depends(get_db)) -> ScanService:
    return ScanService(db=db)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/quota",
    response_model=QuotaResponse,
    summary="Xem quota scan còn lại hôm nay",
)
async def get_scan_quota(
    current_user: User = Depends(require_ai_user),
    redis=Depends(get_redis),
) -> QuotaResponse:
    """Trả về số lượt scan đã dùng, còn lại và thời điểm reset."""
    quota_data = await get_quota_info(current_user.id, redis)
    return QuotaResponse(**quota_data)


@router.post(
    "",
    response_model=ScanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo scan mới — nhận diện vật thể trong ảnh",
)
async def create_scan(
    image: UploadFile = File(..., description="Ảnh JPEG/PNG/HEIC, tối đa 5MB"),
    current_user: User = Depends(require_ai_user),
    service: ScanService = Depends(get_scan_service),
    redis=Depends(get_redis),
) -> ScanResponse:
    """
    Upload ảnh → Gemini nhận diện vật thể → trả danh sách kết quả.

    - Không trừ quota nếu: không có vật thể, Gemini lỗi, ảnh bị reject.
    - Trừ quota khi: scan thành công (status=ok).
    - Tối đa 10 lượt/user/ngày.
    """
    # Đọc bytes từ upload
    image_bytes = await image.read()
    content_type = image.content_type or "image/jpeg"

    # Reserve quota trước (raises 429 nếu hết quota)
    await reserve_scan_quota(current_user.id, redis)

    try:
        result = await service.create_scan(
            user_id=current_user.id,
            image_bytes=image_bytes,
            content_type=content_type,
        )
        # Nếu status=no_object → hoàn trả quota
        if result.status == "no_object":
            await release_scan_quota(current_user.id, redis)
        return result

    except InvalidImageError as exc:
        await release_scan_quota(current_user.id, redis)
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": exc.code, "message": exc.message},
        ) from exc

    except ImageRejectedError as exc:
        await release_scan_quota(current_user.id, redis)
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": exc.code, "message": "Image rejected by safety filter"},
        ) from exc

    except ScanFailedError as exc:
        await release_scan_quota(current_user.id, redis)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"code": exc.code, "message": "Scan failed — please try again"},
        ) from exc

    except AITemporarilyUnavailableError as exc:
        await release_scan_quota(current_user.id, redis)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"code": exc.code, "message": "AI service temporarily unavailable"},
        ) from exc

    except Exception:
        # Unexpected error → hoàn trả quota
        await release_scan_quota(current_user.id, redis)
        raise
