"""app/core/config/__init__.py — Re-export settings để dùng ngắn hơn."""

from .settings import Settings, get_settings, settings

__all__ = ["Settings", "get_settings", "settings"]
