"""
app/integrations/storage/client.py

S3-compatible storage adapter hỗ trợ Cloudflare R2, AWS S3, và MinIO.

Thiết kế:
  - Dùng boto3 (sync) trong thread pool — tránh thêm dependency aioboto3.
  - Mỗi method công khai là async, chạy blocking boto3 trong asyncio.to_thread().
  - Tạo client lười (lazy) để không kết nối lúc import.
  - Toàn bộ exceptions được wrap sang StorageError subclasses.

Quy tắc (từ README):
  - Scan photos → bucket PRIVATE (scans-private).
  - Content đã duyệt → bucket PUBLIC (content-public).
  - DB chỉ lưu object key — KHÔNG lưu presigned URL (hết hạn).
  - Key naming: không chứa PII (email/tên), dùng UUID + timestamp.

Sử dụng:
    storage = StorageClient()
    key = await storage.upload_scan(user_id, image_bytes, "image/jpeg")
    url = await storage.presign_scan(key, ttl=3600)
    await storage.delete(key, bucket=BucketType.PRIVATE)
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from datetime import datetime, timezone
from enum import Enum
from typing import TYPE_CHECKING

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from app.core.config import settings

from .errors import (
    StorageDeleteError,
    StorageKeyNotFoundError,
    StoragePresignError,
    StorageUploadError,
)

if TYPE_CHECKING:
    import types
    from mypy_boto3_s3 import S3Client as BotoS3Client

logger = logging.getLogger(__name__)


class BucketType(str, Enum):
    """Phân loại bucket — ánh xạ sang tên bucket thật từ settings."""

    PRIVATE = "private"
    PUBLIC = "public"


class StorageClient:
    """
    Async wrapper cho boto3 S3 client.

    Thread-safe: mỗi lần gọi tạo boto3 client mới trong thread pool
    vì boto3 session không thread-safe khi chia sẻ.
    """

    def __init__(self) -> None:
        # Lazy — không tạo connection lúc __init__
        self._endpoint = settings.STORAGE_ENDPOINT
        self._region = settings.STORAGE_REGION
        self._access_key = settings.STORAGE_ACCESS_KEY
        self._secret_key = settings.STORAGE_SECRET_KEY
        self._bucket_private = settings.STORAGE_BUCKET_PRIVATE
        self._bucket_public = settings.STORAGE_BUCKET_PUBLIC
        self._presign_ttl = settings.STORAGE_PRESIGN_TTL

    # ── Public API ────────────────────────────────────────────────────────────

    async def upload_scan(
        self,
        user_id: uuid.UUID,
        image_bytes: bytes,
        mime_type: str = "image/jpeg",
    ) -> str:
        """
        Upload ảnh scan của user vào bucket PRIVATE.

        Key format: scans/{user_id}/{YYYYMMDD_HHMMSS}_{random8}.jpg
        Key không chứa PII — chỉ UUID + timestamp + random suffix.

        Returns:
            object key (string) — lưu vào DB.

        Raises:
            StorageUploadError
        """
        key = _build_scan_key(user_id)
        await self._upload(key, image_bytes, mime_type, BucketType.PRIVATE)
        logger.info("Uploaded scan: key=%s size=%d bytes", key, len(image_bytes))
        return key

    async def presign_scan(
        self,
        key: str,
        ttl: int | None = None,
    ) -> str:
        """
        Tạo presigned GET URL cho ảnh scan (bucket private).

        Args:
            key: object key trả về từ upload_scan().
            ttl: seconds, mặc định lấy từ settings.STORAGE_PRESIGN_TTL.

        Returns:
            URL có thời hạn (string).

        Raises:
            StoragePresignError
        """
        return await self._presign(
            key,
            bucket=BucketType.PRIVATE,
            ttl=ttl or self._presign_ttl,
        )

    async def upload_public(
        self,
        key: str,
        data: bytes,
        mime_type: str,
    ) -> str:
        """
        Upload content đã duyệt vào bucket PUBLIC (CDN).

        Returns:
            object key.

        Raises:
            StorageUploadError
        """
        await self._upload(key, data, mime_type, BucketType.PUBLIC)
        logger.info("Uploaded public asset: key=%s", key)
        return key

    async def delete(self, key: str, bucket: BucketType = BucketType.PRIVATE) -> None:
        """
        Xóa object khỏi bucket.

        Raises:
            StorageDeleteError
        """
        bucket_name = self._resolve_bucket(bucket)
        try:
            await asyncio.to_thread(self._delete_sync, key, bucket_name)
            logger.info("Deleted object: bucket=%s key=%s", bucket_name, key)
        except StorageDeleteError:
            raise
        except Exception as exc:
            raise StorageDeleteError(str(exc), key=key) from exc

    async def exists(self, key: str, bucket: BucketType = BucketType.PRIVATE) -> bool:
        """
        Kiểm tra object tồn tại hay không.
        Dùng head_object — nhanh, không tải dữ liệu.
        """
        bucket_name = self._resolve_bucket(bucket)
        try:
            await asyncio.to_thread(self._head_sync, key, bucket_name)
            return True
        except StorageKeyNotFoundError:
            return False
        except Exception:
            return False

    # ── Private helpers ───────────────────────────────────────────────────────

    def _make_client(self) -> "BotoS3Client":
        """
        Tạo boto3 S3 client mới.
        Gọi trong thread pool — không share giữa các coroutines.
        """
        return boto3.client(
            "s3",
            endpoint_url=self._endpoint,
            region_name=self._region,
            aws_access_key_id=self._access_key,
            aws_secret_access_key=self._secret_key,
        )

    def _resolve_bucket(self, bucket: BucketType) -> str:
        if bucket == BucketType.PRIVATE:
            return self._bucket_private
        return self._bucket_public

    # ── Sync methods (chạy trong thread pool) ────────────────────────────────

    def _upload_sync(
        self,
        key: str,
        data: bytes,
        mime_type: str,
        bucket_name: str,
    ) -> None:
        client = self._make_client()
        try:
            client.put_object(
                Bucket=bucket_name,
                Key=key,
                Body=data,
                ContentType=mime_type,
            )
        except (BotoCoreError, ClientError) as exc:
            raise StorageUploadError(str(exc), key=key) from exc

    def _presign_sync(self, key: str, bucket_name: str, ttl: int) -> str:
        client = self._make_client()
        try:
            url: str = client.generate_presigned_url(
                "get_object",
                Params={"Bucket": bucket_name, "Key": key},
                ExpiresIn=ttl,
            )
            return url
        except (BotoCoreError, ClientError) as exc:
            raise StoragePresignError(str(exc), key=key) from exc

    def _delete_sync(self, key: str, bucket_name: str) -> None:
        client = self._make_client()
        try:
            client.delete_object(Bucket=bucket_name, Key=key)
        except (BotoCoreError, ClientError) as exc:
            raise StorageDeleteError(str(exc), key=key) from exc

    def _head_sync(self, key: str, bucket_name: str) -> None:
        """Raises StorageKeyNotFoundError nếu key không tồn tại."""
        client = self._make_client()
        try:
            client.head_object(Bucket=bucket_name, Key=key)
        except ClientError as exc:
            code = exc.response.get("Error", {}).get("Code", "")
            if code in ("404", "NoSuchKey"):
                raise StorageKeyNotFoundError(key=key) from exc
            raise

    # ── Async wrappers ────────────────────────────────────────────────────────

    async def _upload(
        self,
        key: str,
        data: bytes,
        mime_type: str,
        bucket: BucketType,
    ) -> None:
        bucket_name = self._resolve_bucket(bucket)
        try:
            await asyncio.to_thread(self._upload_sync, key, data, mime_type, bucket_name)
        except StorageUploadError:
            raise
        except Exception as exc:
            raise StorageUploadError(str(exc), key=key) from exc

    async def _presign(self, key: str, bucket: BucketType, ttl: int) -> str:
        bucket_name = self._resolve_bucket(bucket)
        try:
            return await asyncio.to_thread(self._presign_sync, key, bucket_name, ttl)
        except StoragePresignError:
            raise
        except Exception as exc:
            raise StoragePresignError(str(exc), key=key) from exc


# ── Utilities ─────────────────────────────────────────────────────────────────

def _build_scan_key(user_id: uuid.UUID) -> str:
    """
    Tạo object key cho scan image.

    Format: scans/{user_id}/{YYYYMMDD_HHMMSS}_{random8}.jpg

    Không chứa PII — UUID của user không phải email hay tên.
    Đủ ngẫu nhiên để tránh enumeration attack.
    """
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    random_suffix = uuid.uuid4().hex[:8]
    return f"scans/{user_id}/{timestamp}_{random_suffix}.jpg"
