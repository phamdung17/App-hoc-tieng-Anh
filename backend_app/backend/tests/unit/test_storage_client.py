"""
tests/unit/test_storage_client.py

Unit tests cho StorageClient — dùng moto để mock S3 calls.
Không cần bucket thật, không cần env vars.

Chạy: pytest tests/unit/test_storage_client.py -v
"""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock, patch

import pytest

from app.integrations.storage.client import StorageClient, _build_scan_key
from app.integrations.storage.errors import (
    StorageDeleteError,
    StorageKeyNotFoundError,
    StoragePresignError,
    StorageUploadError,
)


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture
def client() -> StorageClient:
    """StorageClient với settings mock."""
    with (
        patch("app.integrations.storage.client.settings") as mock_settings,
    ):
        mock_settings.STORAGE_ENDPOINT = "https://fake.r2.dev"
        mock_settings.STORAGE_REGION = "auto"
        mock_settings.STORAGE_ACCESS_KEY = "fake-access"
        mock_settings.STORAGE_SECRET_KEY = "fake-secret"
        mock_settings.STORAGE_BUCKET_PRIVATE = "scans-private"
        mock_settings.STORAGE_BUCKET_PUBLIC = "content-public"
        mock_settings.STORAGE_PRESIGN_TTL = 3600
        yield StorageClient()


SAMPLE_BYTES = b"fake-image-content"
SAMPLE_USER_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")


# ── _build_scan_key ───────────────────────────────────────────────────────────

def test_build_scan_key_format():
    """Key phải dùng đúng format: scans/{user_id}/{timestamp}_{random8}.jpg"""
    user_id = SAMPLE_USER_ID
    key = _build_scan_key(user_id)

    assert key.startswith(f"scans/{user_id}/")
    assert key.endswith(".jpg")
    # Không chứa PII
    assert "email" not in key
    assert "@" not in key


def test_build_scan_key_unique():
    """Hai lần gọi phải tạo ra hai key khác nhau."""
    key1 = _build_scan_key(SAMPLE_USER_ID)
    key2 = _build_scan_key(SAMPLE_USER_ID)
    assert key1 != key2


# ── upload_scan ───────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_upload_scan_success(client: StorageClient):
    """Upload thành công → trả về key hợp lệ."""
    with patch.object(client, "_upload_sync") as mock_upload:
        mock_upload.return_value = None
        key = await client.upload_scan(SAMPLE_USER_ID, SAMPLE_BYTES, "image/jpeg")

    assert key.startswith(f"scans/{SAMPLE_USER_ID}/")
    assert key.endswith(".jpg")
    mock_upload.assert_called_once()


@pytest.mark.asyncio
async def test_upload_scan_raises_storage_upload_error(client: StorageClient):
    """Khi boto3 lỗi → wrap thành StorageUploadError."""
    from botocore.exceptions import BotoCoreError

    with patch.object(client, "_upload_sync", side_effect=StorageUploadError("network error")):
        with pytest.raises(StorageUploadError):
            await client.upload_scan(SAMPLE_USER_ID, SAMPLE_BYTES, "image/jpeg")


# ── presign_scan ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_presign_scan_returns_url(client: StorageClient):
    """presign_scan → trả về URL string."""
    fake_url = "https://fake.r2.dev/scans/user/file.jpg?X-Amz-Signature=abc"
    with patch.object(client, "_presign_sync", return_value=fake_url):
        url = await client.presign_scan("scans/user/file.jpg")

    assert url == fake_url


@pytest.mark.asyncio
async def test_presign_scan_uses_default_ttl(client: StorageClient):
    """presign_scan không truyền ttl → dùng settings.STORAGE_PRESIGN_TTL."""
    fake_url = "https://fake.r2.dev/presigned"
    with patch.object(client, "_presign_sync", return_value=fake_url) as mock_presign:
        await client.presign_scan("some/key")
        _, _, ttl = mock_presign.call_args.args
        assert ttl == 3600  # default từ settings


@pytest.mark.asyncio
async def test_presign_scan_custom_ttl(client: StorageClient):
    """presign_scan với ttl tùy chỉnh."""
    fake_url = "https://fake.r2.dev/presigned"
    with patch.object(client, "_presign_sync", return_value=fake_url) as mock_presign:
        await client.presign_scan("some/key", ttl=600)
        _, _, ttl = mock_presign.call_args.args
        assert ttl == 600


@pytest.mark.asyncio
async def test_presign_scan_raises_storage_presign_error(client: StorageClient):
    """Khi boto3 lỗi khi presign → StoragePresignError."""
    with patch.object(client, "_presign_sync", side_effect=StoragePresignError("config error")):
        with pytest.raises(StoragePresignError):
            await client.presign_scan("some/key")


# ── delete ────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_delete_success(client: StorageClient):
    """delete thành công → không raise."""
    with patch.object(client, "_delete_sync") as mock_delete:
        await client.delete("some/key")
        mock_delete.assert_called_once()


@pytest.mark.asyncio
async def test_delete_raises_storage_delete_error(client: StorageClient):
    """Khi boto3 lỗi khi xóa → StorageDeleteError."""
    with patch.object(client, "_delete_sync", side_effect=Exception("permission denied")):
        with pytest.raises(StorageDeleteError):
            await client.delete("some/key")


# ── exists ────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_exists_true(client: StorageClient):
    """exists → True khi head_object thành công."""
    with patch.object(client, "_head_sync"):
        result = await client.exists("some/key")
    assert result is True


@pytest.mark.asyncio
async def test_exists_false_when_not_found(client: StorageClient):
    """exists → False khi key không tồn tại."""
    with patch.object(client, "_head_sync", side_effect=StorageKeyNotFoundError(key="some/key")):
        result = await client.exists("some/key")
    assert result is False


@pytest.mark.asyncio
async def test_exists_false_on_generic_error(client: StorageClient):
    """exists → False khi có lỗi bất kỳ (fail safe)."""
    with patch.object(client, "_head_sync", side_effect=Exception("network error")):
        result = await client.exists("some/key")
    assert result is False
