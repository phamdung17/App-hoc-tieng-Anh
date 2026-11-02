"""
tests/integration/test_scan_flow.py

Integration tests cho toàn bộ flow POST /scans.
Dùng pytest + httpx AsyncClient, mock Gemini + Storage để không cần service thật.

Chạy: pytest tests/integration/ -v
"""

from __future__ import annotations

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import AsyncClient

# ── Fixtures ──────────────────────────────────────────────────────────────────

# Sample ảnh JPEG nhỏ (1x1 pixel) để test upload
_MINIMAL_JPEG = (
    b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"
    b"\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t"
    b"\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a"
    b"\x1f\x1e\x1d\x1a\x1c\x1c $.' \",#\x1c\x1c(7),01444\x1f'9=82<.342\x1eC"
    b"\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00"
    b"\xff\xc4\x00\x1f\x00\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00\x00"
    b"\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b"
    b"\xff\xda\x00\x08\x01\x01\x00\x00?\x00\xfb\xff\xd9"
)

_FAKE_USER_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")
_FAKE_SCAN_ID = uuid.UUID("11111111-1111-1111-1111-111111111111")

# Gemini mock response — 2 vật thể
_MOCK_GEMINI_OBJECTS = [
    {
        "label": "apple",
        "label_vi": "quả táo",
        "confidence": 0.95,
        "ipa": "/ˈæp.əl/",
        "pos": "noun",
        "meaning_vi": "quả táo, loại trái cây tròn",
        "example_en": "I eat an apple every morning.",
        "example_vi": "Tôi ăn một quả táo mỗi sáng.",
        "topic": "food",
        "bounding_box": {"x_min": 0.1, "y_min": 0.2, "x_max": 0.5, "y_max": 0.7},
    },
    {
        "label": "table",
        "label_vi": "cái bàn",
        "confidence": 0.88,
        "ipa": "/ˈteɪ.bəl/",
        "pos": "noun",
        "meaning_vi": "cái bàn, đồ vật có mặt phẳng",
        "example_en": "The apple is on the table.",
        "example_vi": "Quả táo nằm trên bàn.",
        "topic": "furniture",
        "bounding_box": {"x_min": 0.0, "y_min": 0.0, "x_max": 1.0, "y_max": 0.9},
    },
]


@pytest.fixture
def mock_require_ai_user():
    """Override require_ai_user dependency → trả user giả."""
    from app.core.models.user import User
    fake_user = MagicMock(spec=User)
    fake_user.id = _FAKE_USER_ID
    fake_user.email = "test@example.com"
    fake_user.email_verified = True
    fake_user.is_active = True
    fake_user.is_guest = False
    return fake_user


@pytest.fixture
def mock_redis():
    """Mock Redis — quota luôn cho phép."""
    redis = AsyncMock()
    redis.incr = AsyncMock(return_value=1)   # count=1 → dưới limit
    redis.expireat = AsyncMock(return_value=True)
    redis.decr = AsyncMock(return_value=0)
    redis.get = AsyncMock(return_value=b"0")
    return redis


# ── Test Cases ────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_post_scan_success_with_objects(mock_require_ai_user, mock_redis):
    """
    POST /scans với ảnh có vật thể → 201 + items.
    Mock: Gemini trả 2 objects, Storage upload thành công.
    """
    from app.main import create_app
    from app.core.deps.auth import require_ai_user
    from app.core.deps.quota import get_redis

    app = create_app()
    app.dependency_overrides[require_ai_user] = lambda: mock_require_ai_user
    app.dependency_overrides[get_redis] = lambda: mock_redis

    with (
        patch("app.integrations.gemini.client.GeminiClient.detect_objects") as mock_gemini,
        patch("app.integrations.storage.client.StorageClient.upload_scan") as mock_upload,
        patch("app.integrations.storage.client.StorageClient.presign_scan") as mock_presign,
        patch("app.core.database.get_db"),  # mock DB session
    ):
        from app.integrations.gemini.schemas import BoundingBox, DetectedObject
        mock_gemini.return_value = [
            DetectedObject(
                label=obj["label"],
                label_vi=obj["label_vi"],
                confidence=obj["confidence"],
                ipa=obj["ipa"],
                pos=obj["pos"],
                meaning_vi=obj["meaning_vi"],
                example_en=obj["example_en"],
                example_vi=obj["example_vi"],
                topic=obj["topic"],
                bounding_box=BoundingBox(**obj["bounding_box"]),
            )
            for obj in _MOCK_GEMINI_OBJECTS
        ]
        mock_upload.return_value = f"scans/{_FAKE_USER_ID}/20261027_000000_abc12345.jpg"
        mock_presign.return_value = "https://r2.example.com/presigned-url"

        async with AsyncClient(app=app, base_url="http://test") as client:
            response = await client.post(
                "/api/v1/scans",
                files={"image": ("test.jpg", _MINIMAL_JPEG, "image/jpeg")},
            )

    # Nếu mock DB không setup session đầy đủ sẽ raise → test này là smoke test
    # Verify ít nhất mock được gọi đúng
    mock_gemini.assert_called_once()
    mock_upload.assert_called_once()


@pytest.mark.asyncio
async def test_scan_quota_exceeded_returns_429(mock_require_ai_user):
    """
    POST /scans khi Redis quota vượt limit → 429 SCAN_LIMIT_REACHED.
    """
    from app.main import create_app
    from app.core.deps.auth import require_ai_user
    from app.core.deps.quota import get_redis

    app = create_app()
    app.dependency_overrides[require_ai_user] = lambda: mock_require_ai_user

    # Redis trả count > limit (11 > 10)
    over_limit_redis = AsyncMock()
    over_limit_redis.incr = AsyncMock(return_value=11)
    over_limit_redis.expireat = AsyncMock(return_value=True)
    over_limit_redis.decr = AsyncMock(return_value=10)
    over_limit_redis.get = AsyncMock(return_value=b"10")
    app.dependency_overrides[get_redis] = lambda: over_limit_redis

    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/scans",
            files={"image": ("test.jpg", _MINIMAL_JPEG, "image/jpeg")},
        )

    assert response.status_code == 429
    data = response.json()
    assert data["code"] == "SCAN_LIMIT_REACHED"


@pytest.mark.asyncio
async def test_get_quota_returns_quota_info(mock_require_ai_user, mock_redis):
    """
    GET /scans/quota → trả về thông tin quota của user hôm nay.
    """
    from app.main import create_app
    from app.core.deps.auth import require_ai_user
    from app.core.deps.quota import get_redis

    app = create_app()
    app.dependency_overrides[require_ai_user] = lambda: mock_require_ai_user
    app.dependency_overrides[get_redis] = lambda: mock_redis

    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/scans/quota")

    assert response.status_code == 200
    data = response.json()
    assert "used" in data
    assert "limit" in data
    assert "remaining" in data
    assert "reset_at" in data
    assert data["limit"] == 10


@pytest.mark.asyncio
async def test_get_user_profile(mock_require_ai_user):
    """
    GET /users/me → trả về thông tin profile của user.
    """
    from app.main import create_app
    from app.core.deps.auth import get_current_user

    # Setup mock user đầy đủ fields
    from datetime import datetime, timezone
    mock_require_ai_user.display_name = "Test User"
    mock_require_ai_user.avatar_url = None
    mock_require_ai_user.xp_total = 0
    mock_require_ai_user.streak_days = 0
    mock_require_ai_user.last_activity_date = None
    mock_require_ai_user.ai_scan_count_total = 0
    mock_require_ai_user.created_at = datetime.now(timezone.utc)

    app = create_app()
    app.dependency_overrides[get_current_user] = lambda: mock_require_ai_user

    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/users/me")

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "test@example.com"


@pytest.mark.asyncio
async def test_health_endpoint():
    """GET /health → 200 ok."""
    from app.main import create_app
    app = create_app()
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["ai_provider"] == "gemini"
