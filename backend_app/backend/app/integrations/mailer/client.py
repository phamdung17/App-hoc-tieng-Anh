"""
app/integrations/mailer/client.py

Email client dùng Resend API.

Thiết kế:
  - Resend SDK là sync → chạy trong asyncio.to_thread() giống StorageClient.
  - Nếu RESEND_API_KEY rỗng → log warning và bỏ qua (dev-friendly).
  - Tất cả template HTML đặt trong mailer/templates/ hoặc inline.

Dùng:
    mailer = MailerClient()
    await mailer.send_verify_email(to="user@example.com", token="abc123")
    await mailer.send_password_reset(to="user@example.com", token="xyz789")
"""

from __future__ import annotations

import asyncio
import logging

import resend

from app.core.config import settings

from .errors import MailConfigError, MailSendError

logger = logging.getLogger(__name__)

# Base URL app FE dùng để tạo link trong email
# Trong production thay bằng domain thật
_APP_BASE_URL = "https://app.example.com"
_VERIFY_PATH = "/auth/verify-email"
_RESET_PATH = "/auth/reset-password"


class MailerClient:
    """
    Async wrapper cho Resend email API.

    Nếu RESEND_API_KEY chưa cấu hình → chạy ở "no-op mode":
    log token ra console thay vì gửi email thật.
    Tiện cho dev/test local khi chưa có Resend account.
    """

    def __init__(self) -> None:
        self._api_key = settings.RESEND_API_KEY
        self._from_addr = settings.EMAIL_FROM
        self._noop = not bool(self._api_key)

        if self._noop:
            logger.warning(
                "MailerClient: RESEND_API_KEY chưa cấu hình — "
                "email sẽ KHÔNG được gửi, chỉ log ra console."
            )
        else:
            resend.api_key = self._api_key

    # ── Public Methods ────────────────────────────────────────────────────────

    async def send_verify_email(self, to: str, token: str) -> None:
        """
        Gửi email xác minh tài khoản.

        Args:
            to: địa chỉ email người nhận.
            token: verify token (từ auth service).
        """
        verify_url = f"{_APP_BASE_URL}{_VERIFY_PATH}?token={token}"

        if self._noop:
            logger.info(
                "📧 [NO-OP] Verify email for %s | URL: %s",
                to,
                verify_url,
            )
            return

        subject = "Xác minh tài khoản — App học tiếng Anh"
        html = _render_verify_email(to, verify_url)
        await self._send(to=to, subject=subject, html=html)

    async def send_password_reset(self, to: str, token: str) -> None:
        """
        Gửi email đặt lại mật khẩu.

        Args:
            to: địa chỉ email người nhận.
            token: reset token.
        """
        reset_url = f"{_APP_BASE_URL}{_RESET_PATH}?token={token}"

        if self._noop:
            logger.info(
                "📧 [NO-OP] Password reset for %s | URL: %s",
                to,
                reset_url,
            )
            return

        subject = "Đặt lại mật khẩu — App học tiếng Anh"
        html = _render_reset_email(to, reset_url)
        await self._send(to=to, subject=subject, html=html)

    # ── Private ───────────────────────────────────────────────────────────────

    async def _send(self, to: str, subject: str, html: str) -> None:
        """
        Gửi email qua Resend API (chạy sync trong thread pool).

        Raises:
            MailSendError: Khi Resend API trả lỗi.
        """
        try:
            await asyncio.to_thread(
                self._send_sync,
                to=to,
                subject=subject,
                html=html,
            )
            logger.info("Email sent: to=%s subject=%r", to, subject)
        except MailSendError:
            raise
        except Exception as exc:
            logger.error("Failed to send email to %s: %s", to, exc)
            raise MailSendError(str(exc), recipient=to) from exc

    def _send_sync(self, to: str, subject: str, html: str) -> None:
        """Sync Resend send — chạy trong thread pool."""
        try:
            resend.Emails.send({
                "from": self._from_addr,
                "to": [to],
                "subject": subject,
                "html": html,
            })
        except Exception as exc:
            raise MailSendError(str(exc), recipient=to) from exc


# ── HTML Templates ────────────────────────────────────────────────────────────

def _render_verify_email(email: str, verify_url: str) -> str:
    """Template HTML đơn giản cho email xác minh."""
    return f"""
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><title>Xác minh tài khoản</title></head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <h2 style="color: #4F46E5;">🎓 App Học Tiếng Anh + AI</h2>
  <p>Xin chào! Vui lòng xác minh địa chỉ email của bạn để sử dụng đầy đủ tính năng AI.</p>
  <div style="text-align: center; margin: 30px 0;">
    <a href="{verify_url}"
       style="background: #4F46E5; color: white; padding: 14px 28px;
              border-radius: 8px; text-decoration: none; font-weight: bold;">
      Xác minh Email
    </a>
  </div>
  <p style="color: #666; font-size: 14px;">
    Link có hiệu lực trong <strong>24 giờ</strong>.<br>
    Nếu bạn không đăng ký tài khoản này, hãy bỏ qua email này.
  </p>
  <hr style="border: none; border-top: 1px solid #eee;">
  <p style="color: #999; font-size: 12px;">
    Email gửi tới: {email}<br>
    Không trả lời email này.
  </p>
</body>
</html>
"""


def _render_reset_email(email: str, reset_url: str) -> str:
    """Template HTML cho email đặt lại mật khẩu."""
    return f"""
<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><title>Đặt lại mật khẩu</title></head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <h2 style="color: #4F46E5;">🎓 App Học Tiếng Anh + AI</h2>
  <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.</p>
  <div style="text-align: center; margin: 30px 0;">
    <a href="{reset_url}"
       style="background: #DC2626; color: white; padding: 14px 28px;
              border-radius: 8px; text-decoration: none; font-weight: bold;">
      Đặt Lại Mật Khẩu
    </a>
  </div>
  <p style="color: #666; font-size: 14px;">
    Link có hiệu lực trong <strong>1 giờ</strong>.<br>
    Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.
  </p>
  <hr style="border: none; border-top: 1px solid #eee;">
  <p style="color: #999; font-size: 12px;">
    Email gửi tới: {email}<br>
    Không trả lời email này.
  </p>
</body>
</html>
"""
