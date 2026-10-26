"""
tests/unit/test_gemini_client.py

Unit tests cho GeminiClient — dùng httpx mock (không gọi API thật).
Covers:
  - Detect thành công: trả list DetectedObject
  - Response rỗng: trả list rỗng (không crash)
  - Timeout: raise GeminiTimeoutError
  - Connect error: raise GeminiUnavailableError
  - HTTP 429: raise GeminiQuotaExceededError
  - HTTP 500: raise GeminiUnavailableError
  - Safety rejection (finishReason=SAFETY): raise GeminiSafetyRejectionError
  - JSON sai → retry → thành công lần 2
  - JSON sai → retry → vẫn sai → GeminiInvalidResponseError
  - BoundingBox validation: x_max <= x_min → ValidationError
  - Strip markdown code block
  - Label được normalize về lowercase
"""

from __future__ import annotations

import json
from typing import Any
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import httpx
from pydantic import ValidationError

from app.integrations.gemini.client import GeminiClient, _strip_markdown_code_block
from app.integrations.gemini.errors import (
    GeminiInvalidResponseError,
    GeminiQuotaExceededError,
    GeminiSafetyRejectionError,
    GeminiTimeoutError,
    GeminiUnavailableError,
)
from app.integrations.gemini.schemas import BoundingBox, DetectedObject


# ── Fixtures & Helpers ────────────────────────────────────────────────────────

VALID_GEMINI_RESPONSE = {
    "candidates": [
        {
            "content": {
                "parts": [
                    {
                        "text": json.dumps({
                            "objects": [
                                {
                                    "label": "Apple",   # uppercase — sẽ bị normalize
                                    "label_vi": "quả táo",
                                    "confidence": 0.95,
                                    "ipa": "/ˈæp.əl/",
                                    "pos": "noun",
                                    "meaning_vi": "quả táo, loại trái cây tròn",
                                    "example_en": "I eat an apple every morning.",
                                    "example_vi": "Tôi ăn một quả táo mỗi sáng.",
                                    "topic": "food",
                                    "bounding_box": {
                                        "x_min": 0.1,
                                        "y_min": 0.2,
                                        "x_max": 0.5,
                                        "y_max": 0.7,
                                    },
                                }
                            ]
                        })
                    }
                ]
            },
            "finishReason": "STOP",
        }
    ]
}

EMPTY_GEMINI_RESPONSE = {
    "candidates": [
        {
            "content": {"parts": [{"text": json.dumps({"objects": []})}]},
            "finishReason": "STOP",
        }
    ]
}

SAFETY_REJECTED_RESPONSE = {
    "candidates": [
        {
            "content": {"parts": []},
            "finishReason": "SAFETY",
        }
    ]
}

INVALID_JSON_RESPONSE = {
    "candidates": [
        {
            "content": {"parts": [{"text": "not valid json {{{"}]},
            "finishReason": "STOP",
        }
    ]
}

SAMPLE_IMAGE = b"fake-image-bytes"


def _make_httpx_response(data: dict, status_code: int = 200) -> httpx.Response:
    """Tạo mock httpx.Response."""
    return httpx.Response(
        status_code=status_code,
        content=json.dumps(data).encode(),
        headers={"content-type": "application/json"},
    )


def _make_client() -> GeminiClient:
    """Tạo GeminiClient với settings mock."""
    with patch("app.integrations.gemini.client.settings") as mock_settings:
        mock_settings.GEMINI_API_KEY = "test-api-key"
        mock_settings.GEMINI_MODEL = "gemini-2.0-flash"
        mock_settings.GEMINI_TIMEOUT = 10
        client = GeminiClient()
    client._api_key = "test-api-key"
    client._model = "gemini-2.0-flash"
    client._timeout = 10
    return client


# ── Tests: Success Cases ──────────────────────────────────────────────────────

class TestDetectObjectsSuccess:
    """Test cases cho kịch bản detect thành công."""

    @pytest.mark.asyncio
    async def test_returns_detected_objects(self):
        """Detect thành công → trả list DetectedObject đúng."""
        client = _make_client()
        mock_response = _make_httpx_response(VALID_GEMINI_RESPONSE)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            result = await client.detect_objects(SAMPLE_IMAGE)

        assert len(result) == 1
        obj = result[0]
        assert isinstance(obj, DetectedObject)
        assert obj.label == "apple"        # lowercase
        assert obj.label_vi == "quả táo"
        assert obj.confidence == 0.95
        assert obj.ipa == "/ˈæp.əl/"
        assert obj.pos == "noun"
        assert obj.topic == "food"
        assert obj.example_en == "I eat an apple every morning."
        assert obj.example_vi == "Tôi ăn một quả táo mỗi sáng."

    @pytest.mark.asyncio
    async def test_bounding_box_correct(self):
        """BoundingBox được parse đúng."""
        client = _make_client()
        mock_response = _make_httpx_response(VALID_GEMINI_RESPONSE)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            result = await client.detect_objects(SAMPLE_IMAGE)

        bbox = result[0].bounding_box
        assert bbox.x_min == 0.1
        assert bbox.y_min == 0.2
        assert bbox.x_max == 0.5
        assert bbox.y_max == 0.7

    @pytest.mark.asyncio
    async def test_label_normalized_to_lowercase(self):
        """Label uppercase trong response được normalize về lowercase."""
        client = _make_client()
        mock_response = _make_httpx_response(VALID_GEMINI_RESPONSE)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            result = await client.detect_objects(SAMPLE_IMAGE)

        # Response có "Apple" (uppercase) nhưng model normalize về "apple"
        assert result[0].label == "apple"

    @pytest.mark.asyncio
    async def test_empty_objects_list(self):
        """Không nhận diện được vật thể → trả list rỗng, không raise."""
        client = _make_client()
        mock_response = _make_httpx_response(EMPTY_GEMINI_RESPONSE)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            result = await client.detect_objects(SAMPLE_IMAGE)

        assert result == []


# ── Tests: Error Cases ────────────────────────────────────────────────────────

class TestDetectObjectsErrors:
    """Test cases cho các kịch bản lỗi."""

    @pytest.mark.asyncio
    async def test_timeout_raises_gemini_timeout_error(self):
        """Timeout → GeminiTimeoutError."""
        client = _make_client()

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.side_effect = httpx.TimeoutException("timeout")
            with pytest.raises(GeminiTimeoutError):
                await client.detect_objects(SAMPLE_IMAGE)

    @pytest.mark.asyncio
    async def test_connect_error_raises_unavailable(self):
        """Không kết nối được → GeminiUnavailableError."""
        client = _make_client()

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.side_effect = httpx.ConnectError("connection refused")
            with pytest.raises(GeminiUnavailableError):
                await client.detect_objects(SAMPLE_IMAGE)

    @pytest.mark.asyncio
    async def test_http_429_raises_quota_exceeded(self):
        """HTTP 429 → GeminiQuotaExceededError."""
        client = _make_client()
        mock_response = _make_httpx_response({}, status_code=429)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            with pytest.raises(GeminiQuotaExceededError):
                await client.detect_objects(SAMPLE_IMAGE)

    @pytest.mark.asyncio
    async def test_http_500_raises_unavailable(self):
        """HTTP 500 → GeminiUnavailableError."""
        client = _make_client()
        mock_response = _make_httpx_response({"error": "internal"}, status_code=500)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            with pytest.raises(GeminiUnavailableError):
                await client.detect_objects(SAMPLE_IMAGE)

    @pytest.mark.asyncio
    async def test_safety_rejection(self):
        """finishReason=SAFETY → GeminiSafetyRejectionError."""
        client = _make_client()
        mock_response = _make_httpx_response(SAFETY_REJECTED_RESPONSE)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            with pytest.raises(GeminiSafetyRejectionError):
                await client.detect_objects(SAMPLE_IMAGE)

    @pytest.mark.asyncio
    async def test_invalid_json_retries_and_fails(self):
        """JSON sai → retry → vẫn sai → GeminiInvalidResponseError."""
        client = _make_client()
        mock_response = _make_httpx_response(INVALID_JSON_RESPONSE)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            with pytest.raises(GeminiInvalidResponseError):
                await client.detect_objects(SAMPLE_IMAGE)

        # Phải gọi API 2 lần (retry 1 lần)
        assert mock_post.call_count == 2

    @pytest.mark.asyncio
    async def test_invalid_json_retries_then_succeeds(self):
        """JSON sai lần 1, đúng lần 2 → trả kết quả thành công."""
        client = _make_client()

        bad_response = _make_httpx_response(INVALID_JSON_RESPONSE)
        good_response = _make_httpx_response(VALID_GEMINI_RESPONSE)

        with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
            mock_post.side_effect = [bad_response, good_response]
            result = await client.detect_objects(SAMPLE_IMAGE)

        assert len(result) == 1
        assert result[0].label == "apple"
        assert mock_post.call_count == 2


# ── Tests: Schema Validation ──────────────────────────────────────────────────

class TestBoundingBoxValidation:
    """Test Pydantic validation cho BoundingBox."""

    def test_valid_bounding_box(self):
        """BoundingBox hợp lệ → tạo thành công."""
        bbox = BoundingBox(x_min=0.1, y_min=0.2, x_max=0.5, y_max=0.7)
        assert bbox.width == pytest.approx(0.4)
        assert bbox.height == pytest.approx(0.5)

    def test_x_max_less_than_x_min_raises(self):
        """x_max <= x_min → ValidationError."""
        with pytest.raises(ValidationError, match="x_max"):
            BoundingBox(x_min=0.5, y_min=0.1, x_max=0.3, y_max=0.8)

    def test_y_max_less_than_y_min_raises(self):
        """y_max <= y_min → ValidationError."""
        with pytest.raises(ValidationError, match="y_max"):
            BoundingBox(x_min=0.1, y_min=0.8, x_max=0.5, y_max=0.3)

    def test_x_max_equal_x_min_raises(self):
        """x_max == x_min (zero width) → ValidationError."""
        with pytest.raises(ValidationError):
            BoundingBox(x_min=0.3, y_min=0.1, x_max=0.3, y_max=0.8)

    def test_out_of_range_raises(self):
        """Giá trị ngoài 0..1 → ValidationError."""
        with pytest.raises(ValidationError):
            BoundingBox(x_min=-0.1, y_min=0.0, x_max=0.5, y_max=0.8)

    def test_to_xywh(self):
        """to_xywh() trả (x, y, w, h) đúng."""
        bbox = BoundingBox(x_min=0.1, y_min=0.2, x_max=0.5, y_max=0.7)
        x, y, w, h = bbox.to_xywh()
        assert x == pytest.approx(0.1)
        assert y == pytest.approx(0.2)
        assert w == pytest.approx(0.4)
        assert h == pytest.approx(0.5)


# ── Tests: Utility Functions ──────────────────────────────────────────────────

class TestStripMarkdownCodeBlock:
    """Test _strip_markdown_code_block helper."""

    def test_strips_json_code_block(self):
        raw = '```json\n{"objects": []}\n```'
        assert _strip_markdown_code_block(raw) == '{"objects": []}'

    def test_strips_plain_code_block(self):
        raw = '```\n{"objects": []}\n```'
        assert _strip_markdown_code_block(raw) == '{"objects": []}'

    def test_no_code_block_unchanged(self):
        raw = '{"objects": []}'
        assert _strip_markdown_code_block(raw) == '{"objects": []}'

    def test_whitespace_stripped(self):
        raw = '   {"objects": []}   '
        assert _strip_markdown_code_block(raw) == '{"objects": []}'
