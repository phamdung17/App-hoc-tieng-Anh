"""
app/integrations/storage/errors.py

Domain errors cho storage integration.
Mọi lỗi bên dưới đều wrap boto3/botocore exceptions.
"""

from __future__ import annotations


class StorageError(Exception):
    """Base class cho tất cả storage errors."""

    def __init__(self, message: str = "", key: str = "") -> None:
        self.key = key
        super().__init__(message)


class StorageUploadError(StorageError):
    """Upload file lên S3/R2 thất bại."""


class StoragePresignError(StorageError):
    """Không thể tạo presigned URL (config sai, endpoint lỗi...)."""


class StorageDeleteError(StorageError):
    """Xóa object thất bại."""


class StorageKeyNotFoundError(StorageError):
    """Object key không tồn tại trong bucket."""
