"""
app/integrations/gemini/errors.py

Lỗi adapter cho Gemini API.
Map các lỗi provider → exception types có ngữ nghĩa rõ ràng.
Scan service sẽ map những lỗi này → HTTP error codes.
"""


class GeminiError(Exception):
    """Base class cho mọi lỗi Gemini integration."""
    pass


class GeminiTimeoutError(GeminiError):
    """Gemini API không phản hồi trong thời gian cho phép (GEMINI_TIMEOUT).

    Map → HTTP 503 SCAN_FAILED, không trừ quota.
    """
    def __init__(self, msg: str = "Gemini API timeout") -> None:
        super().__init__(msg)


class GeminiUnavailableError(GeminiError):
    """Gemini API không khả dụng (connect error, 5xx, v.v.).

    Map → HTTP 503 AI_TEMPORARILY_UNAVAILABLE, không trừ quota.
    """
    def __init__(self, msg: str = "Gemini API unavailable") -> None:
        super().__init__(msg)


class GeminiQuotaExceededError(GeminiError):
    """Hết quota Gemini API phía Google (HTTP 429).

    Map → HTTP 503 AI_TEMPORARILY_UNAVAILABLE, không trừ quota user.
    """
    def __init__(self, msg: str = "Gemini API quota exceeded (rate limited)") -> None:
        super().__init__(msg)


class GeminiInvalidResponseError(GeminiError):
    """Response từ Gemini không parse được sau khi đã retry.

    Map → HTTP 503 SCAN_FAILED, không trừ quota.
    """
    def __init__(self, msg: str = "Invalid or unparseable Gemini response") -> None:
        super().__init__(msg)


class GeminiSafetyRejectionError(GeminiError):
    """Gemini safety filter từ chối ảnh (finishReason = SAFETY).

    Map → HTTP 422 IMAGE_REJECTED, không trừ quota.
    """
    def __init__(self, msg: str = "Image rejected by Gemini safety filter") -> None:
        super().__init__(msg)
