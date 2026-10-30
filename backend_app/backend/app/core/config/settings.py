"""
app/core/config/settings.py

Đọc và validate toàn bộ cấu hình từ environment variables / .env file.
Là nguồn cấu hình duy nhất — mọi module import `from app.core.config import settings`.
Fail fast khi thiếu biến bắt buộc (Pydantic sẽ raise ValueError lúc import).
"""

from __future__ import annotations

from functools import lru_cache

from pydantic import AnyHttpUrl, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Toàn bộ cấu hình ứng dụng, đọc từ môi trường / .env."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",       # Bỏ qua biến không khai báo
        case_sensitive=False, # Không phân biệt HOA/thường
    )

    # ── App ─────────────────────────────────────────────────────────────
    APP_ENV: str = "development"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    LOG_LEVEL: str = "INFO"

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str | list[str]) -> list[str]:
        """Chấp nhận chuỗi phân tách bằng dấu phẩy hoặc list."""
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

    # ── PostgreSQL ───────────────────────────────────────────────────────
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20

    # ── Redis / ARQ ──────────────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/0"

    # ── Auth (JWT) ───────────────────────────────────────────────────────
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    @field_validator("JWT_SECRET_KEY")
    @classmethod
    def validate_jwt_secret(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("JWT_SECRET_KEY phải có ít nhất 32 ký tự.")
        return v

    # ── Storage (S3-compatible: R2 hoặc AWS S3) ──────────────────────────
    STORAGE_ENDPOINT: str
    STORAGE_REGION: str = "auto"
    STORAGE_BUCKET_PRIVATE: str = "scans-private"
    STORAGE_BUCKET_PUBLIC: str = "content-public"
    STORAGE_ACCESS_KEY: str
    STORAGE_SECRET_KEY: str
    STORAGE_PRESIGN_TTL: int = 3600  # giây

    # ── Gemini API ───────────────────────────────────────────────────────
    # Thay thế YOLO-World container. Key chỉ ở server, không bao giờ gửi cho FE.
    GEMINI_API_KEY: str
    GEMINI_MODEL: str = "gemini-2.0-flash"
    GEMINI_TIMEOUT: int = 30  # giây

    # ── AI Safety & Quota ────────────────────────────────────────────────
    SCAN_QUOTA_PER_USER_DAILY: int = 10
    SCAN_SYSTEM_BUDGET_DAILY: int = 500

    # ── Email (Resend) ───────────────────────────────────────────────────
    RESEND_API_KEY: str = ""
    EMAIL_FROM: str = "noreply@example.com"

    # ── Firebase Cloud Messaging ─────────────────────────────────────────
    FIREBASE_CREDENTIALS_PATH: str = ""

    # ── Helpers ──────────────────────────────────────────────────────────
    @property
    def is_production(self) -> bool:
        return self.APP_ENV == "production"

    @property
    def is_development(self) -> bool:
        return self.APP_ENV == "development"

    @property
    def is_testing(self) -> bool:
        return self.APP_ENV == "testing"

    @model_validator(mode="after")
    def check_production_settings(self) -> "Settings":
        """Trong production: đảm bảo không dùng giá trị placeholder."""
        if self.is_production:
            if "REPLACE_WITH" in self.JWT_SECRET_KEY.upper():
                raise ValueError(
                    "JWT_SECRET_KEY chứa placeholder — không hợp lệ trong production."
                )
        return self


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Trả về Settings singleton (cached). Dùng khi cần override trong test."""
    return Settings()


# Singleton dùng trực tiếp trong app
settings: Settings = get_settings()
