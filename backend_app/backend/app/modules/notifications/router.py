"""
app/modules/notifications/router.py

FastAPI router cho Notifications module.
Endpoints:
  - POST /notifications/send-reminder       : Gửi thông báo đẩy từ xa tới user hiện tại
  - POST /notifications/broadcast-reminders : Chạy tác vụ nền quét và nhắc học hàng loạt
  - GET  /notifications/status              : Kiểm tra trạng thái cấu hình FCM và device token
"""

from __future__ import annotations

from fastapi import APIRouter, Body, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.deps.auth import get_current_user
from app.core.models.user import User

from .schemas import (
    BroadcastReminderResponse,
    NotificationStatusResponse,
    SendReminderRequest,
    SendReminderResponse,
)
from .service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


def get_notification_service(db: AsyncSession = Depends(get_db)) -> NotificationService:
    return NotificationService(db=db)


@router.post(
    "/send-reminder",
    response_model=SendReminderResponse,
    summary="Gửi thông báo nhắc học từ xa tới thiết bị hiện tại",
)
async def send_reminder(
    body: SendReminderRequest | None = None,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(get_notification_service),
) -> SendReminderResponse:
    """
    Gửi push notification từ máy chủ (Server Push qua FCM) tới thiết bị của user đang đăng nhập.
    Dùng để kiểm tra hoặc kích hoạt thông báo nhắc học ngay lập tức.
    """
    title = body.title if body else None
    reminder_body = body.body if body else None
    result = await service.send_reminder_to_user(
        user=current_user,
        custom_title=title,
        custom_body=reminder_body,
    )
    return SendReminderResponse(**result)


@router.post(
    "/broadcast-reminders",
    response_model=BroadcastReminderResponse,
    summary="Kích hoạt tác vụ nền gửi nhắc học cho tất cả người dùng chưa học hôm nay",
)
async def broadcast_reminders(
    service: NotificationService = Depends(get_notification_service),
) -> BroadcastReminderResponse:
    """
    Tác vụ nền chạy quét định kỳ:
    - Tìm tất cả người dùng có FCM token.
    - Lọc những người chưa có hoạt động học trong ngày hôm nay.
    - Đẩy thông báo từ xa qua FCM nhắc nhở giữ chuỗi Streak.
    """
    result = await service.run_reminder_background_job()
    return BroadcastReminderResponse(**result)


@router.get(
    "/status",
    response_model=NotificationStatusResponse,
    summary="Kiểm tra trạng thái FCM và token của thiết bị",
)
async def get_notification_status(
    current_user: User = Depends(get_current_user),
) -> NotificationStatusResponse:
    """Trả về trạng thái cấu hình FCM trên máy chủ và token của user hiện tại."""
    token = current_user.fcm_token
    return NotificationStatusResponse(
        fcm_configured=bool(settings.FIREBASE_CREDENTIALS_PATH),
        has_token=bool(token),
        fcm_token_preview=(token[:16] + "...") if token else None,
        display_name=current_user.display_name,
    )
