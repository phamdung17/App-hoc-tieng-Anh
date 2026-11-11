"""
app/modules/scan/service.py

Business logic cho scan module.
Thực thi đúng flow 8 bước từ scan/README.md:

1. require_ai_user (xử lý ở dep layer)
2. Check quota atomically (Redis)
3. Validate + resize ảnh (Pillow, max 1280px)
4. Upload ảnh vào S3/R2 (scans-private)
5. Gọi GeminiClient.detect_objects() — 1 lần duy nhất
6. Validate + dedupe + limit 8 items, confidence >= 0.5
7. Tra lemma trong words catalog (dùng lại cache nếu có)
8. Lưu Scan + ScanItem vào DB, tăng quota, trả kết quả

Không gọi Gemini lần 2. API key chỉ ở server.
"""

from __future__ import annotations

import io
import logging
import uuid
from datetime import datetime, timezone

from PIL import Image
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.models.scan import Scan, ScanItem
from app.core.models.word import Word
from app.integrations.storage.client import (
    create_private_image_url,
    upload_private_image,
)
from app.integrations.gemini import (
    GeminiClient,
    GeminiInvalidResponseError,
    GeminiQuotaExceededError,
    GeminiSafetyRejectionError,
    GeminiTimeoutError,
    GeminiUnavailableError,
    DetectedObject,
)

from .errors import (
    AITemporarilyUnavailableError,
    ImageRejectedError,
    InvalidImageError,
    ScanFailedError,
)
from .schemas import (
    BoundingBoxResponse,
    ScanItemResponse,
    ScanResponse,
)

logger = logging.getLogger(__name__)

# Cấu hình xử lý ảnh
_MAX_IMAGE_BYTES = 5 * 1024 * 1024   # 5 MB
_MAX_DIMENSION_PX = 1280
_JPEG_QUALITY = 85
_ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/heic", "image/heif", "image/webp"}
_MIN_CONFIDENCE = 0.5
_MAX_ITEMS = 8


class ScanService:
    """
    Service xử lý toàn bộ nghiệp vụ scan.
    Được inject vào router qua FastAPI Depends.
    """

    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._gemini = GeminiClient()
        # TODO (Ngày 4 sau): inject StorageClient, RedisClient
        # self._storage = StorageClient()
        # self._redis = redis_client

    # ── Public Methods ────────────────────────────────────────────────────

    async def create_scan(
        self,
        user_id: uuid.UUID,
        image_bytes: bytes,
        content_type: str,
    ) -> ScanResponse:
        """
        Thực thi toàn bộ flow POST /scans.

        Raises:
            InvalidImageError: Ảnh sai format hoặc quá lớn.
            ScanFailedError: Gemini timeout hoặc JSON không parse được.
            AITemporarilyUnavailableError: Gemini quota/unavailable.
            ImageRejectedError: Ảnh bị safety filter.
        """
        # ── Step 3: Validate + resize ảnh ────────────────────────────────
        processed_bytes, mime_type = await self._validate_and_resize_image(
            image_bytes, content_type
        )

        # ── Step 4: Upload ảnh vào storage ───────────────────────────────
        image_key = await self._upload_image(user_id, processed_bytes, mime_type)
        image_url = await create_private_image_url(image_key)

        # ── Step 5: Gọi Gemini API ────────────────────────────────────────
        detected_objects = await self._call_gemini(processed_bytes, mime_type)

        # Không có vật thể → trả no_object, không trừ quota
        if not detected_objects:
            scan = await self._save_scan(
                user_id=user_id,
                image_key=image_key,
                mime_type=mime_type,
                status="no_object",
                items_data=[],
            )
            return ScanResponse(
                id=scan.id,
                status="no_object",
                image_url=image_url,
                items=[],
                object_count=0,
                created_at=scan.created_at,
            )

        # ── Step 6: Filter + dedupe + limit ──────────────────────────────
        filtered = self._filter_and_dedupe(detected_objects)

        # ── Step 7: Tra catalog, cache nếu chưa có ────────────────────────
        items_with_word_ids = await self._resolve_word_catalog(filtered)

        # ── Step 8: Lưu DB + tăng quota ──────────────────────────────────
        scan = await self._save_scan(
            user_id=user_id,
            image_key=image_key,
            mime_type=mime_type,
            status="ok",
            items_data=items_with_word_ids,
        )
        # The router keeps the Redis reservation only after the DB commit succeeds.

        # ── Xây dựng response ─────────────────────────────────────────────
        return self._build_response(scan, image_url)

    # ── Private Helpers ───────────────────────────────────────────────────

    async def _validate_and_resize_image(
        self, image_bytes: bytes, content_type: str
    ) -> tuple[bytes, str]:
        """
        Validate format và kích thước ảnh. Resize nếu cần.
        Luôn trả ra JPEG để tối ưu upload size.

        Returns:
            (processed_bytes, "image/jpeg")

        Raises:
            InvalidImageError: Nếu ảnh không hợp lệ.
        """
        # Kiểm tra MIME type
        if content_type not in _ALLOWED_MIME_TYPES:
            raise InvalidImageError(f"Unsupported image format: {content_type}")

        # Kiểm tra file size
        if len(image_bytes) > _MAX_IMAGE_BYTES:
            raise InvalidImageError("IMAGE_TOO_LARGE")

        # Decode và validate với Pillow
        try:
            image = Image.open(io.BytesIO(image_bytes))
            image.verify()                      # Detect corrupt files
            image = Image.open(io.BytesIO(image_bytes))  # Reopen sau verify
            image = image.convert("RGB")        # Strip alpha, normalize
        except Exception as exc:
            logger.warning("Invalid image: %s", exc)
            raise InvalidImageError("INVALID_IMAGE_FORMAT") from exc

        # Resize nếu cần
        w, h = image.size
        if w > _MAX_DIMENSION_PX or h > _MAX_DIMENSION_PX:
            image.thumbnail((_MAX_DIMENSION_PX, _MAX_DIMENSION_PX), Image.LANCZOS)
            logger.debug("Resized image from %dx%d to %dx%d", w, h, *image.size)

        # Encode sang JPEG
        output = io.BytesIO()
        image.save(output, format="JPEG", quality=_JPEG_QUALITY, optimize=True)
        return output.getvalue(), "image/jpeg"

    async def _upload_image(
        self, user_id: uuid.UUID, image_bytes: bytes, mime_type: str
    ) -> str:
        """Upload normalized image bytes to the configured private S3 bucket."""
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        key = f"scans/{user_id}/{timestamp}_{uuid.uuid4().hex[:8]}.jpg"
        await upload_private_image(key, image_bytes, mime_type)
        return key

    async def _call_gemini(
        self, image_bytes: bytes, mime_type: str
    ) -> list[DetectedObject]:
        """
        Gọi GeminiClient và map exceptions → domain errors.

        Raises:
            ScanFailedError: Timeout hoặc JSON invalid.
            AITemporarilyUnavailableError: Rate limit hoặc service down.
            ImageRejectedError: Safety filter từ chối ảnh.
        """
        try:
            return await self._gemini.detect_objects(
                image_bytes=image_bytes,
                mime_type=mime_type,
                max_objects=_MAX_ITEMS,
            )
        except GeminiTimeoutError as exc:
            logger.error("Gemini timeout: %s", exc)
            raise ScanFailedError("SCAN_FAILED") from exc
        except GeminiInvalidResponseError as exc:
            logger.error("Gemini invalid response after retry: %s", exc)
            raise ScanFailedError("SCAN_FAILED") from exc
        except GeminiUnavailableError as exc:
            logger.error("Gemini unavailable: %s", exc)
            raise AITemporarilyUnavailableError() from exc
        except GeminiQuotaExceededError as exc:
            logger.warning("Gemini quota exceeded: %s", exc)
            raise AITemporarilyUnavailableError() from exc
        except GeminiSafetyRejectionError as exc:
            logger.warning("Image rejected by Gemini safety: %s", exc)
            raise ImageRejectedError() from exc

    def _filter_and_dedupe(
        self, objects: list[DetectedObject]
    ) -> list[DetectedObject]:
        """
        Lọc theo confidence >= 0.5, dedupe theo label, limit 8 items.
        Sắp xếp theo confidence giảm dần trước khi dedupe.
        """
        # Sắp xếp confidence cao → thấp
        sorted_objects = sorted(objects, key=lambda o: o.confidence, reverse=True)

        seen_labels: set[str] = set()
        filtered: list[DetectedObject] = []

        for obj in sorted_objects:
            if obj.confidence < _MIN_CONFIDENCE:
                continue
            if obj.label in seen_labels:
                continue          # Bỏ duplicate label
            if len(filtered) >= _MAX_ITEMS:
                break

            seen_labels.add(obj.label)
            filtered.append(obj)

        logger.debug(
            "Filtered: %d objects (from %d)", len(filtered), len(objects)
        )
        return filtered

    async def _resolve_word_catalog(
        self, objects: list[DetectedObject]
    ) -> list[tuple[DetectedObject, uuid.UUID | None]]:
        """
        Tra từng lemma trong bảng words:
        - Đã có → dùng word_id hiện tại (không ghi đè)
        - Chưa có → insert word mới vào catalog
        Trả list (DetectedObject, word_id | None).
        """
        result: list[tuple[DetectedObject, uuid.UUID | None]] = []

        for obj in objects:
            # Tra catalog theo lemma
            stmt = select(Word).where(Word.lemma == obj.label)
            existing = (await self._db.execute(stmt)).scalar_one_or_none()

            if existing:
                # Dùng word đã cache — KHÔNG ghi đè
                word_id = existing.id
                logger.debug("Word cache hit: lemma=%r", obj.label)
            else:
                # Tạo word mới từ Gemini card
                new_word = Word(
                    lemma=obj.label,
                    ipa=obj.ipa,
                    pos=obj.pos,
                    meaning_vi=obj.meaning_vi,
                    example_en=obj.example_en,
                    example_vi=obj.example_vi,
                    topic=obj.topic,
                    is_ai_generated=True,
                )
                self._db.add(new_word)
                await self._db.flush()   # Lấy ID mà không commit
                word_id = new_word.id
                logger.info("New word cached: lemma=%r id=%s", obj.label, word_id)

            result.append((obj, word_id))

        return result

    async def _save_scan(
        self,
        user_id: uuid.UUID,
        image_key: str,
        mime_type: str,
        status: str,
        items_data: list[tuple[DetectedObject, uuid.UUID | None]],
    ) -> Scan:
        """Lưu Scan + ScanItem records vào DB."""
        scan = Scan(
            user_id=user_id,
            image_key=image_key,
            image_mime_type=mime_type,
            status=status,
            object_count=len(items_data),
            gemini_model=settings.GEMINI_MODEL,
        )
        self._db.add(scan)
        await self._db.flush()  # Lấy scan.id

        for obj, word_id in items_data:
            bbox_x, bbox_y, bbox_w, bbox_h = obj.bounding_box.to_xywh()
            item = ScanItem(
                scan_id=scan.id,
                word_id=word_id,
                label=obj.label,
                label_vi=obj.label_vi,
                confidence=obj.confidence,
                ipa=obj.ipa,
                pos=obj.pos,
                meaning_vi=obj.meaning_vi,
                example_en=obj.example_en,
                example_vi=obj.example_vi,
                topic=obj.topic,
                bbox_x=bbox_x,
                bbox_y=bbox_y,
                bbox_w=bbox_w,
                bbox_h=bbox_h,
            )
            # `Scan.items` uses lazy="noload". Keep the in-memory collection
            # populated so `_build_response` can return the items just created.
            scan.items.append(item)
            self._db.add(item)

        # Generate ScanItem IDs and persist them in the current transaction
        # before `_build_response` serializes the in-memory relationship.
        await self._db.flush()

        # commit sẽ được gọi bởi get_db() dependency sau khi return
        return scan

    def _build_response(self, scan: Scan, image_url: str) -> ScanResponse:
        """Xây dựng ScanResponse từ Scan ORM object."""
        items = [
            ScanItemResponse(
                id=item.id,
                label=item.label,
                label_vi=item.label_vi,
                confidence=item.confidence,
                ipa=item.ipa,
                pos=item.pos,
                meaning_vi=item.meaning_vi,
                example_en=item.example_en,
                example_vi=item.example_vi,
                topic=item.topic,
                bounding_box=BoundingBoxResponse(
                    x=item.bbox_x,
                    y=item.bbox_y,
                    w=item.bbox_w,
                    h=item.bbox_h,
                ),
                is_saved=item.is_saved,
                word_id=item.word_id,
            )
            for item in (scan.items or [])
        ]

        return ScanResponse(
            id=scan.id,
            status=scan.status,
            image_url=image_url,
            items=items,
            object_count=scan.object_count,
            created_at=scan.created_at,
        )
