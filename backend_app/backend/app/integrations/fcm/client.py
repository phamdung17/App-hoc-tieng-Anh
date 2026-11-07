"""
app/integrations/fcm/client.py

Client gửi thông báo đẩy qua Firebase Cloud Messaging (FCM).
Hỗ trợ:
- Chế độ Production: Gửi qua Firebase Admin SDK / FCM HTTP v1.
- Chế độ Development / Test: Simulator log và fallback mượt mà khi chưa có credentials file.
"""

from __future__ import annotations

import logging
import os
from typing import Any

from app.core.config import settings

logger = logging.getLogger(__name__)


class FcmClient:
    """Client tương tác với Firebase Cloud Messaging."""

    def __init__(self, credentials_path: str | None = None) -> None:
        self._credentials_path = credentials_path or settings.FIREBASE_CREDENTIALS_PATH
        self._firebase_app = None
        self._init_firebase()

    def _init_firebase(self) -> None:
        """Khởi tạo Firebase Admin SDK nếu có file service account."""
        if not self._credentials_path:
            logger.info("FCM: Chạy ở chế độ Simulator (chưa cấu hình FIREBASE_CREDENTIALS_PATH)")
            return

        if not os.path.exists(self._credentials_path):
            logger.warning(
                "FCM: Không tìm thấy file credentials tại %s. Chuyển sang chế độ Simulator.",
                self._credentials_path,
            )
            return

        try:
            import firebase_admin
            from firebase_admin import credentials

            if not firebase_admin._apps:
                cred = credentials.Certificate(self._credentials_path)
                self._firebase_app = firebase_admin.initialize_app(cred)
                logger.info("FCM: Firebase Admin SDK đã khởi tạo thành công.")
            else:
                self._firebase_app = firebase_admin.get_app()
        except Exception as exc:
            logger.warning("FCM: Không thể khởi tạo Firebase Admin SDK: %s", exc)
            self._firebase_app = None

    async def send_notification(
        self,
        token: str,
        title: str,
        body: str,
        data: dict[str, Any] | None = None,
    ) -> bool:
        """
        Gửi thông báo đẩy đến một device FCM token cụ thể.

        Returns:
            bool: True nếu gửi thành công (hoặc simulator đã chấp nhận), False nếu thất bại.
        """
        clean_token = token.strip()
        if not clean_token:
            logger.warning("FCM: Token rỗng, bỏ qua gửi thông báo.")
            return False

        payload_data = {k: str(v) for k, v in (data or {}).items()}

        # ── 1. Gửi qua Firebase Admin nếu khả dụng ────────────────────────────
        if self._firebase_app:
            try:
                from firebase_admin import messaging

                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data=payload_data,
                    token=clean_token,
                )
                response = messaging.send(message)
                logger.info("FCM: Đã gửi thông báo từ xa thành công. Message ID: %s", response)
                return True
            except Exception as exc:
                logger.error("FCM: Gửi thông báo thất bại: %s", exc)
                return False

        # ── 2. Chế độ Simulator / Development ─────────────────────────────────
        logger.info(
            "FCM [Simulator PUSH]: Gửi tới token=%s... | Tiêu đề: '%s' | Nội dung: '%s' | Data: %s",
            clean_token[:16],
            title,
            body,
            payload_data,
        )
        return True


# Singleton client
fcm_client = FcmClient()
