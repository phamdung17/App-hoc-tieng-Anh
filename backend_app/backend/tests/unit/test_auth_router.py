"""
tests/unit/test_auth_router.py

Unit tests for Auth API router (/api/v1/auth):
1. Register: success (201 Created), duplicate email (409 Conflict).
2. Login: success (200 OK), invalid credentials (401 Unauthorized).
3. Token Refresh: success (200 OK), invalid token (401 Unauthorized).
4. Get Current User (/auth/me): success with Bearer token authentication.
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
from app.modules.auth.errors import EmailAlreadyRegisteredError, InvalidCredentialsError
from app.modules.auth.router import get_auth_service
from app.modules.auth.schemas import AuthResponse, TokenResponse, UserResponse


@pytest_asyncio.fixture
async def auth_test_client():
    mock_service = AsyncMock()
    app.dependency_overrides[get_auth_service] = lambda: mock_service

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        yield client, mock_service

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_register_success(auth_test_client):
    client, mock_service = auth_test_client
    user_id = uuid.uuid4()
    now = datetime.now(timezone.utc)

    mock_service.register.return_value = AuthResponse(
        user=UserResponse(
            id=user_id,
            email="learner@lingoup.com",
            display_name="Learner",
            email_verified=False,
            is_guest=False,
            xp_total=0,
            streak_days=0,
            created_at=now,
        ),
        tokens=TokenResponse(
            access_token="fake-access-token",
            refresh_token="fake-refresh-token",
            token_type="bearer",
            expires_in=900,
        ),
    )

    resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "learner@lingoup.com",
            "password": "Password123!",
            "display_name": "Learner",
        },
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["user"]["email"] == "learner@lingoup.com"
    assert data["tokens"]["access_token"] == "fake-access-token"
    assert data["tokens"]["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_email_conflict(auth_test_client):
    client, mock_service = auth_test_client
    mock_service.register.side_effect = EmailAlreadyRegisteredError()

    resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "existing@lingoup.com",
            "password": "Password123!",
            "display_name": "Existing",
        },
    )
    assert resp.status_code == 409
    data = resp.json()
    assert data["detail"]["code"] == "EMAIL_ALREADY_REGISTERED"
    assert "already registered" in data["detail"]["message"]


@pytest.mark.asyncio
async def test_login_success(auth_test_client):
    client, mock_service = auth_test_client
    user_id = uuid.uuid4()
    now = datetime.now(timezone.utc)

    mock_service.login.return_value = AuthResponse(
        user=UserResponse(
            id=user_id,
            email="learner@lingoup.com",
            display_name="Learner",
            email_verified=True,
            is_guest=False,
            xp_total=150,
            streak_days=5,
            created_at=now,
        ),
        tokens=TokenResponse(
            access_token="login-access-token",
            refresh_token="login-refresh-token",
            token_type="bearer",
            expires_in=900,
        ),
    )

    resp = await client.post(
        "/api/v1/auth/login",
        json={"email": "learner@lingoup.com", "password": "Password123!"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["user"]["email"] == "learner@lingoup.com"
    assert data["tokens"]["access_token"] == "login-access-token"
    assert data["user"]["streak_days"] == 5


@pytest.mark.asyncio
async def test_login_invalid_credentials(auth_test_client):
    client, mock_service = auth_test_client
    mock_service.login.side_effect = InvalidCredentialsError()

    resp = await client.post(
        "/api/v1/auth/login",
        json={"email": "learner@lingoup.com", "password": "WrongPassword123!"},
    )
    assert resp.status_code == 401
    data = resp.json()
    assert data["detail"]["code"] == "INVALID_CREDENTIALS"


@pytest.mark.asyncio
async def test_refresh_token_success(auth_test_client):
    client, mock_service = auth_test_client
    mock_service.refresh.return_value = TokenResponse(
        access_token="new-access-token",
        refresh_token="new-refresh-token",
        token_type="bearer",
        expires_in=900,
    )

    resp = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "valid-refresh-token"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["access_token"] == "new-access-token"
    assert data["refresh_token"] == "new-refresh-token"


@pytest.mark.asyncio
async def test_refresh_token_invalid(auth_test_client):
    client, mock_service = auth_test_client
    mock_service.refresh.side_effect = InvalidCredentialsError()

    resp = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "expired-token"},
    )
    assert resp.status_code == 401
    data = resp.json()
    assert data["detail"]["code"] == "INVALID_REFRESH_TOKEN"


@pytest.mark.asyncio
async def test_get_current_user_me(auth_test_client):
    client, _ = auth_test_client
    user_id = uuid.uuid4()
    now = datetime.now(timezone.utc)

    mock_user = User(
        id=user_id,
        email="me@lingoup.com",
        display_name="Me Myself",
        hashed_password="fake-hashed-pw",
        email_verified=True,
        is_guest=False,
        xp_total=500,
        streak_days=10,
        created_at=now,
    )

    app.dependency_overrides[get_current_user] = lambda: mock_user

    resp = await client.get("/api/v1/auth/me")
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == "me@lingoup.com"
    assert data["display_name"] == "Me Myself"
    assert data["streak_days"] == 10
    assert data["xp_total"] == 500
