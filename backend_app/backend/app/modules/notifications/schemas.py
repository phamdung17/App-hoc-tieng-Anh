"""
app/modules/notifications/schemas.py

Pydantic schemas cho Notifications module.
"""

from __future__ import annotations

from typing import Optional
from pydantic import BaseModel


class SendReminderRequest(BaseModel):
    title: Optional[str] = None
    body: Optional[str] = None


class SendReminderResponse(BaseModel):
    sent: bool
    title: str
    body: str
    user_id: str
    fcm_token: Optional[str] = None
    message: Optional[str] = None


class BroadcastReminderResponse(BaseModel):
    total_candidates: int
    sent_count: int
    skipped_already_studied: int
    date: str


class NotificationStatusResponse(BaseModel):
    fcm_configured: bool
    has_token: bool
    fcm_token_preview: Optional[str] = None
    display_name: str
