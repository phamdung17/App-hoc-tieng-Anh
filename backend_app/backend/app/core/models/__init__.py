"""app/core/models/__init__.py — Import all models để Alembic autogenerate nhận diện."""

from .base import TimestampMixin
from .user import User
from .word import Word
from .scan import Scan, ScanItem

__all__ = ["TimestampMixin", "User", "Word", "Scan", "ScanItem"]
