"""
app/integrations/fcm/client.py

Firebase Cloud Messaging client.

Dùng để gửi push notification cho mobile app (Flutter).
Hiện tại là no-op nếu FIREBASE_CREDENTIALS_PATH chưa cấu hình.

Cách bật:
1. Tạo project Firebase → Project Settings → Service accounts → Generate new private key
2. Lưu file JSON vào /secrets/firebase-service-account.json
3. Set FIREBASE_CREDENTIALS_PATH=/secrets/firebase-service-account.json trong .env
"""

from __future__ import annotations

import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


class FCMClient:
    """
    Firebase Cloud Messaging client.
    No-op nếu FIREBASE_CREDENTIALS_PATH không được cấu hình.
    """

    def __init__(self) -> None:
        self._enabled = bool(settings.FIREBASE_CREDENTIALS_PATH)
        if not self._enabled:
            logger.warning(
                "FCMClient: FIREBASE_CREDENTIALS_PATH chưa cấu hình — "
                "push notifications sẽ bị bỏ qua."
            )
        else:
            self._init_firebase()

    def _init_firebase(self) -> None:
        """Khởi tạo Firebase Admin SDK."""
        try:
            import firebase_admin
            from firebase_admin import credentials
            if not firebase_admin._apps:
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin SDK initialized.")
        except Exception as exc:
            logger.error("Failed to initialize Firebase: %s", exc)
            self._enabled = False

    async def send_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: dict | None = None,
    ) -> bool:
        """
        Gửi push notification đến một thiết bị.

        Args:
            fcm_token: FCM token của thiết bị.
            title: Tiêu đề notification.
            body: Nội dung notification.
            data: Payload data tùy chọn (key-value strings).

        Returns:
            True nếu gửi thành công, False nếu không.
        """
        if not self._enabled:
            logger.info(
                "📱 [NO-OP] FCM notification: title=%r body=%r token=%s...",
                title, body, fcm_token[:8] if fcm_token else "None",
            )
            return False

        try:
            import asyncio
            return await asyncio.to_thread(
                self._send_sync, fcm_token, title, body, data or {}
            )
        except Exception as exc:
            logger.error("FCM send failed: %s", exc)
            return False

    def _send_sync(
        self, fcm_token: str, title: str, body: str, data: dict
    ) -> bool:
        """Sync FCM send — chạy trong thread pool."""
        from firebase_admin import messaging
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in data.items()},
            token=fcm_token,
        )
        messaging.send(message)
        logger.info("FCM sent: token=%s... title=%r", fcm_token[:8], title)
        return True
