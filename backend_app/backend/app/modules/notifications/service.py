"""
app/modules/notifications/service.py

Service điều phối thông báo đẩy từ xa (Remote Push Notifications & Tác vụ nền nhắc học).
"""

from __future__ import annotations

import logging
import uuid
from datetime import date
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.models.progress import UserDailyActivity
from app.core.models.user import User
from app.integrations.fcm.client import FcmClient, fcm_client

logger = logging.getLogger(__name__)


class NotificationService:
    """Nghiệp vụ gửi thông báo và quản lý tác vụ nền nhắc học."""

    def __init__(self, db: AsyncSession, client: FcmClient | None = None) -> None:
        self._db = db
        self._fcm = client or fcm_client

    async def send_reminder_to_user(
        self,
        user: User,
        custom_title: str | None = None,
        custom_body: str | None = None,
    ) -> dict[str, Any]:
        """
        Gửi thông báo nhắc học ngay lập tức đến thiết bị của user.
        Dùng cho kiểm tra / demo tính năng push notification từ xa.
        """
        token = user.fcm_token
        if not token:
            logger.warning("User %s chưa đăng ký FCM token.", user.id)
            return {
                "sent": False,
                "message": "Thiết bị chưa đăng ký FCM token. Hãy mở app và bật nhận thông báo.",
                "user_id": str(user.id),
            }

        title = custom_title or "🔥 Đến giờ học cùng LingoUp rồi!"
        body = custom_body or (
            f"Chào {user.display_name}! Hãy hoàn thành 1 bài học hôm nay "
            f"để giữ vững chuỗi {user.streak_days} ngày liên tiếp nhé."
        )

        success = await self._fcm.send_notification(
            token=token,
            title=title,
            body=body,
            data={
                "type": "study_reminder",
                "user_id": str(user.id),
                "streak_days": str(user.streak_days),
            },
        )

        return {
            "sent": success,
            "title": title,
            "body": body,
            "fcm_token": token[:16] + "...",
            "user_id": str(user.id),
        }

    async def run_reminder_background_job(self) -> dict[str, Any]:
        """
        Tác vụ nền (Background Worker Job) quét tất cả người dùng:
        - Bỏ qua người dùng không có FCM token hoặc tài khoản bị khóa.
        - Bỏ qua người dùng ĐÃ hoàn thành bài học hôm nay (có bản ghi trong user_daily_activities).
        - Gửi push notification nhắc nhở tới những người CHƯA học hôm nay.
        """
        today = date.today()

        # 1. Lấy danh sách user đang active có fcm_token
        stmt = select(User).where(
            User.fcm_token.isnot(None),
            User.is_active == True,  # noqa: E712
        )
        users = (await self._db.execute(stmt)).scalars().all()

        sent_count = 0
        skipped_count = 0

        for user in users:
            # 2. Kiểm tra xem user đã học hôm nay chưa
            activity_stmt = select(UserDailyActivity).where(
                UserDailyActivity.user_id == user.id,
                UserDailyActivity.activity_date == today,
            )
            activity = (await self._db.execute(activity_stmt)).scalar_one_or_none()

            if activity and activity.xp_earned > 0:
                skipped_count += 1
                continue

            # 3. Gửi thông báo nhắc nhở từ xa
            title = "🔥 Đừng để ngọn lửa Streak bị tắt!"
            body = (
                f"Bạn ơi, hôm nay chưa ghi nhận bài học nào. Dành 5 phút luyện tập "
                f"để duy trì chuỗi {user.streak_days} ngày streak của bạn nhé!"
            )

            ok = await self._fcm.send_notification(
                token=user.fcm_token,  # type: ignore[arg-type]
                title=title,
                body=body,
                data={
                    "type": "streak_reminder",
                    "user_id": str(user.id),
                },
            )
            if ok:
                sent_count += 1

        logger.info(
            "Tác vụ nền FCM Reminder hoàn tất: Tổng %d users | Đã gửi: %d | Bỏ qua đã học: %d",
            len(users),
            sent_count,
            skipped_count,
        )

        return {
            "total_candidates": len(users),
            "sent_count": sent_count,
            "skipped_already_studied": skipped_count,
            "date": str(today),
        }
