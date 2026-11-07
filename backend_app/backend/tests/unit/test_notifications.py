"""
tests/unit/test_notifications.py

Unit tests cho module Notifications và FCM push service:
- POST /notifications/send-reminder
- POST /notifications/broadcast-reminders
- GET  /notifications/status
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.core.deps.auth import get_current_user
from app.core.models.user import User
from app.main import app
from app.modules.notifications.router import get_notification_service


@pytest_asyncio.fixture
async def notifications_client():
    mock_service = AsyncMock()
    app.dependency_overrides[get_notification_service] = lambda: mock_service

    mock_user = User(
        id=uuid.uuid4(),
        email="test_fcm@lingoup.com",
        display_name="FCM Learner",
        hashed_password="pw",
        fcm_token="sample-device-token-12345",
        streak_days=7,
        xp_total=140,
        email_verified=True,
        is_active=True,
        created_at=datetime.now(timezone.utc),
    )
    app.dependency_overrides[get_current_user] = lambda: mock_user

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        yield client, mock_service, mock_user

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_send_reminder_endpoint(notifications_client):
    client, mock_service, mock_user = notifications_client
    mock_service.send_reminder_to_user.return_value = {
        "sent": True,
        "title": "🔥 Đến giờ học cùng LingoUp rồi!",
        "body": "Hãy hoàn thành 1 bài học hôm nay để giữ chuỗi!",
        "user_id": str(mock_user.id),
        "fcm_token": "sample-device-to...",
    }

    resp = await client.post("/api/v1/notifications/send-reminder", json={})
    assert resp.status_code == 200
    data = resp.json()
    assert data["sent"] is True
    assert "LingoUp" in data["title"]


@pytest.mark.asyncio
async def test_broadcast_reminders_endpoint(notifications_client):
    client, mock_service, _ = notifications_client
    mock_service.run_reminder_background_job.return_value = {
        "total_candidates": 10,
        "sent_count": 8,
        "skipped_already_studied": 2,
        "date": "2026-11-08",
    }

    resp = await client.post("/api/v1/notifications/broadcast-reminders")
    assert resp.status_code == 200
    data = resp.json()
    assert data["sent_count"] == 8
    assert data["skipped_already_studied"] == 2


@pytest.mark.asyncio
async def test_notification_status_endpoint(notifications_client):
    client, _, mock_user = notifications_client

    resp = await client.get("/api/v1/notifications/status")
    assert resp.status_code == 200
    data = resp.json()
    assert data["has_token"] is True
    assert data["display_name"] == "FCM Learner"
