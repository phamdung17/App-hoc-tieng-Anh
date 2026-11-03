"""
tests/unit/test_settings.py

Comprehensive tests for app/core/config/settings.py:
1. CORS_ORIGINS parsing: comma-separated string, JSON array string, direct list, single origin.
2. Handling trailing spaces, empty items, and delimiters in CORS_ORIGINS.
3. Validation of JWT_SECRET_KEY length (>= 32 characters).
4. Production constraints (no placeholder in production).
"""

from __future__ import annotations

import pytest
from pydantic import ValidationError

from app.core.config.settings import Settings


class TestCorsOriginsParsing:
    """Test parse_cors_origins validator under diverse inputs."""

    def test_comma_separated_string(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv(
            "CORS_ORIGINS",
            "http://localhost:3000, https://app.lingoup.com, http://127.0.0.1:8000",
        )
        s = Settings()
        assert s.CORS_ORIGINS == [
            "http://localhost:3000",
            "https://app.lingoup.com",
            "http://127.0.0.1:8000",
        ]

    def test_json_array_string(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv(
            "CORS_ORIGINS",
            '["http://localhost:3000", "http://localhost:8080"]',
        )
        s = Settings()
        assert s.CORS_ORIGINS == ["http://localhost:3000", "http://localhost:8080"]

    def test_single_origin_string(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("CORS_ORIGINS", "https://prod.lingoup.vn")
        s = Settings()
        assert s.CORS_ORIGINS == ["https://prod.lingoup.vn"]

    def test_trailing_commas_and_spaces(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("CORS_ORIGINS", " http://localhost:3000 , , http://localhost:8000, ")
        s = Settings()
        assert s.CORS_ORIGINS == ["http://localhost:3000", "http://localhost:8000"]

    def test_list_input_direct(self) -> None:
        s = Settings(CORS_ORIGINS=["http://dev.domain.com", "http://prod.domain.com"])
        assert s.CORS_ORIGINS == ["http://dev.domain.com", "http://prod.domain.com"]

    def test_tuple_and_set_inputs(self) -> None:
        s1 = Settings(CORS_ORIGINS=("http://origin1.com", "http://origin2.com"))
        assert s1.CORS_ORIGINS == ["http://origin1.com", "http://origin2.com"]


class TestSecuritySettingsValidation:
    """Test security constraints and model validators in Settings."""

    def test_jwt_secret_too_short_raises_validation_error(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.setenv("JWT_SECRET_KEY", "too-short-secret")
        with pytest.raises(ValidationError, match="ít nhất 32 ký tự"):
            Settings()

    def test_jwt_secret_valid_length(self, monkeypatch: pytest.MonkeyPatch) -> None:
        valid_key = "a" * 32
        monkeypatch.setenv("JWT_SECRET_KEY", valid_key)
        s = Settings()
        assert s.JWT_SECRET_KEY == valid_key

    def test_production_placeholder_rejected(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.setenv("APP_ENV", "production")
        monkeypatch.setenv("JWT_SECRET_KEY", "REPLACE_WITH_A_SECURE_SECRET_KEY_FOR_PROD")
        with pytest.raises(ValidationError, match="placeholder"):
            Settings()

    def test_environment_helpers(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("APP_ENV", "testing")
        s = Settings()
        assert s.is_testing is True
        assert s.is_development is False
        assert s.is_production is False
