"""
app/modules/scan/errors.py

Domain errors cho scan module.
Được map → HTTP responses trong exception handlers hoặc trong router.
"""


class ScanDomainError(Exception):
    """Base error cho scan module."""
    def __init__(self, code: str, message: str = "") -> None:
        self.code = code
        self.message = message or code
        super().__init__(message or code)


class ScanFailedError(ScanDomainError):
    """Gemini call thất bại — không trừ quota."""
    def __init__(self, code: str = "SCAN_FAILED") -> None:
        super().__init__(code)


class AITemporarilyUnavailableError(ScanDomainError):
    """Gemini quota/unavailable — không trừ quota."""
    def __init__(self) -> None:
        super().__init__("AI_TEMPORARILY_UNAVAILABLE")


class ImageRejectedError(ScanDomainError):
    """Ảnh bị safety filter từ chối — không trừ quota."""
    def __init__(self) -> None:
        super().__init__("IMAGE_REJECTED")


class ScanQuotaExceededError(ScanDomainError):
    """User đã dùng hết quota scan hôm nay."""
    def __init__(self, remaining: int = 0, reset_at: str = "") -> None:
        super().__init__("SCAN_LIMIT_REACHED")
        self.remaining = remaining
        self.reset_at = reset_at


class InvalidImageError(ScanDomainError):
    """Ảnh không hợp lệ (sai format, quá lớn, corrupt)."""
    def __init__(self, reason: str = "INVALID_IMAGE") -> None:
        super().__init__(reason)


class AuthRequiredError(ScanDomainError):
    """User chưa đăng nhập."""
    def __init__(self) -> None:
        super().__init__("AUTH_REQUIRED_FOR_AI")


class EmailNotVerifiedError(ScanDomainError):
    """Email user chưa được xác minh."""
    def __init__(self) -> None:
        super().__init__("EMAIL_NOT_VERIFIED")
