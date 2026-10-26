"""app/integrations/gemini/__init__.py — Public API của Gemini integration package."""

from .client import GeminiClient
from .errors import (
    GeminiError,
    GeminiInvalidResponseError,
    GeminiQuotaExceededError,
    GeminiSafetyRejectionError,
    GeminiTimeoutError,
    GeminiUnavailableError,
)
from .schemas import BoundingBox, DetectedObject, GeminiDetectionResponse

__all__ = [
    # Client
    "GeminiClient",
    # Schemas
    "BoundingBox",
    "DetectedObject",
    "GeminiDetectionResponse",
    # Errors
    "GeminiError",
    "GeminiTimeoutError",
    "GeminiUnavailableError",
    "GeminiQuotaExceededError",
    "GeminiInvalidResponseError",
    "GeminiSafetyRejectionError",
]
