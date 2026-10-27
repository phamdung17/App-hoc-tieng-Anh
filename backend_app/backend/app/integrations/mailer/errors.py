"""
app/integrations/mailer/errors.py

Domain errors cho mailer integration.
"""

from __future__ import annotations


class MailerError(Exception):
    """Base class cho tất cả mailer errors."""

    def __init__(self, message: str = "", recipient: str = "") -> None:
        self.recipient = recipient
        super().__init__(message)


class MailSendError(MailerError):
    """Gửi email thất bại (Resend API lỗi)."""


class MailConfigError(MailerError):
    """Cấu hình email sai (thiếu API key, domain chưa verify...)."""
