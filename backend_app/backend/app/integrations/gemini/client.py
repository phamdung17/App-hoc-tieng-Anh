"""
app/integrations/gemini/client.py

Google Gemini API client cho object detection từ ảnh.
Thay thế YOLO-World detector container — chỉ cần API key + HTTP.

Nguyên tắc:
- Không log ảnh/base64
- Timeout cấu hình từ settings
- Retry tối đa 1 lần khi JSON lỗi cấu trúc (theo scan README)
- Không retry khi timeout/network error (tránh tốn quota)
- API key chỉ lấy từ settings, không bao giờ gửi cho FE
"""

from __future__ import annotations

import base64
import json
import logging
from typing import Final

import httpx
from pydantic import ValidationError

from app.core.config import settings

from .errors import (
    GeminiInvalidResponseError,
    GeminiQuotaExceededError,
    GeminiSafetyRejectionError,
    GeminiTimeoutError,
    GeminiUnavailableError,
)
from .prompts import OBJECT_DETECTION_PROMPT
from .schemas import DetectedObject, GeminiDetectionResponse

logger = logging.getLogger(__name__)

_GEMINI_BASE_URL: Final = "https://generativelanguage.googleapis.com/v1beta"
_DEFAULT_MAX_OBJECTS: Final = 8


class GeminiClient:
    """
    Async HTTP client gọi Gemini generateContent API để nhận diện vật thể.

    Dùng httpx.AsyncClient, mỗi call tạo client mới (stateless).
    Connection pooling có thể thêm sau nếu cần optimize.

    Usage:
        client = GeminiClient()
        objects = await client.detect_objects(image_bytes, mime_type="image/jpeg")
    """

    def __init__(self) -> None:
        self._api_key = settings.GEMINI_API_KEY
        self._model = settings.GEMINI_MODEL
        self._timeout = settings.GEMINI_TIMEOUT

    # ── Public API ────────────────────────────────────────────────────────

    async def detect_objects(
        self,
        image_bytes: bytes,
        mime_type: str = "image/jpeg",
        max_objects: int = _DEFAULT_MAX_OBJECTS,
    ) -> list[DetectedObject]:
        """
        Gửi ảnh tới Gemini API, trả về danh sách vật thể nhận diện.

        - Retry tối đa 1 lần khi response JSON sai cấu trúc.
        - Không retry khi timeout/network/quota error.

        Args:
            image_bytes: Raw bytes của ảnh (đã resize/compress trước khi gọi).
            mime_type: MIME type của ảnh, mặc định "image/jpeg".
            max_objects: Số vật thể tối đa yêu cầu Gemini trả về.

        Returns:
            list[DetectedObject]: Có thể rỗng nếu không nhận diện được.

        Raises:
            GeminiTimeoutError: Quá thời gian chờ.
            GeminiUnavailableError: Lỗi kết nối hoặc server error.
            GeminiQuotaExceededError: Rate limited (HTTP 429).
            GeminiSafetyRejectionError: Ảnh bị safety filter từ chối.
            GeminiInvalidResponseError: JSON sai sau khi đã retry.
        """
        url = f"{_GEMINI_BASE_URL}/models/{self._model}:generateContent?key={self._api_key}"
        payload = self._build_payload(image_bytes, mime_type, max_objects)

        raw_response = await self._call_api(url, payload)
        raw_text = self._extract_text(raw_response)

        # Thử parse lần 1
        try:
            return self._parse_detection(raw_text)
        except (GeminiInvalidResponseError, ValidationError):
            logger.warning("Gemini: lần parse đầu thất bại, retry lần 2...")

        # Retry lần 2 — gọi API lại
        raw_response = await self._call_api(url, payload)
        raw_text = self._extract_text(raw_response)
        return self._parse_detection(raw_text)  # Raise nếu vẫn fail

    # ── Private helpers ───────────────────────────────────────────────────

    def _build_payload(
        self, image_bytes: bytes, mime_type: str, max_objects: int
    ) -> dict:
        """Xây dựng request payload cho Gemini generateContent."""
        # Encode base64 — KHÔNG LOG chuỗi này
        image_b64 = base64.b64encode(image_bytes).decode("utf-8")

        return {
            "contents": [
                {
                    "parts": [
                        {
                            "inlineData": {
                                "mimeType": mime_type,
                                "data": image_b64,
                            }
                        },
                        {
                            "text": OBJECT_DETECTION_PROMPT.format(
                                max_objects=max_objects
                            )
                        },
                    ]
                }
            ],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.1,       # Deterministic hơn cho detection
                "topP": 0.95,
                "maxOutputTokens": 2048,
            },
            "safetySettings": [
                # Giảm threshold để không block ảnh thông thường
                {
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_ONLY_HIGH"
                },
                {
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_ONLY_HIGH"
                },
            ],
        }

    async def _call_api(self, url: str, payload: dict) -> dict:
        """Gọi Gemini HTTP API, xử lý connection/timeout/status errors."""
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            try:
                response = await client.post(url, json=payload)
            except httpx.TimeoutException as exc:
                logger.error("Gemini API timeout sau %ds", self._timeout)
                raise GeminiTimeoutError() from exc
            except httpx.ConnectError as exc:
                logger.error("Gemini API connect error: %s", exc)
                raise GeminiUnavailableError("Cannot connect to Gemini API") from exc
            except httpx.HTTPError as exc:
                logger.error("Gemini API HTTP error: %s", exc)
                raise GeminiUnavailableError(str(exc)) from exc

        # Xử lý HTTP status
        if response.status_code == 429:
            logger.warning("Gemini API rate limited (429)")
            raise GeminiQuotaExceededError()
        if response.status_code >= 500:
            logger.error("Gemini API server error: %d", response.status_code)
            raise GeminiUnavailableError(
                f"Gemini API server error: {response.status_code}"
            )
        if response.status_code != 200:
            logger.error("Gemini API unexpected status: %d", response.status_code)
            raise GeminiUnavailableError(
                f"Gemini API returned {response.status_code}"
            )

        return response.json()

    def _extract_text(self, data: dict) -> str:
        """
        Trích xuất phần text JSON từ Gemini response.
        Kiểm tra finishReason để phát hiện safety rejection.
        """
        try:
            candidate = data["candidates"][0]

            # Kiểm tra safety finish reason
            finish_reason = candidate.get("finishReason", "STOP")
            if finish_reason == "SAFETY":
                logger.warning("Gemini safety filter rejected the image")
                raise GeminiSafetyRejectionError()

            text: str = candidate["content"]["parts"][0]["text"]
            return text.strip()

        except GeminiSafetyRejectionError:
            raise
        except (KeyError, IndexError, TypeError) as exc:
            logger.error("Gemini response structure unexpected: %s | data=%s", exc, _safe_log(data))
            raise GeminiInvalidResponseError(
                f"Unexpected response structure: {exc}"
            ) from exc

    def _parse_detection(self, raw_text: str) -> list[DetectedObject]:
        """Parse text JSON → list[DetectedObject]."""
        try:
            # Gemini có thể wrap trong ```json ... ``` — strip nếu có
            cleaned = _strip_markdown_code_block(raw_text)
            parsed = GeminiDetectionResponse.model_validate_json(cleaned)
            logger.debug(
                "Gemini detection: %d objects found", len(parsed.objects)
            )
            return parsed.objects
        except (ValueError, ValidationError, json.JSONDecodeError) as exc:
            logger.warning("Gemini parse failed: %s | raw=%r", exc, raw_text[:200])
            raise GeminiInvalidResponseError(str(exc)) from exc


# ── Module-level helpers ──────────────────────────────────────────────────────

def _strip_markdown_code_block(text: str) -> str:
    """Loại bỏ ```json ... ``` wrapper nếu model vô tình thêm vào."""
    text = text.strip()
    if text.startswith("```"):
        lines = text.splitlines()
        # Bỏ dòng đầu (```json) và dòng cuối (```)
        inner = lines[1:] if lines[0].startswith("```") else lines
        if inner and inner[-1].strip() == "```":
            inner = inner[:-1]
        text = "\n".join(inner)
    return text


def _safe_log(data: dict) -> str:
    """Log response nhưng KHÔNG log data ảnh base64."""
    try:
        safe = {k: v for k, v in data.items() if k != "contents"}
        return str(safe)[:500]
    except Exception:
        return "<unprintable>"
