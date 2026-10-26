"""
app/core/security/password.py

Bcrypt password hashing — dùng passlib.
Không bao giờ lưu plain text password.
"""

from passlib.context import CryptContext

_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain: str) -> str:
    """Hash password bằng bcrypt."""
    return _ctx.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    """So sánh plain password với hashed. Trả False nếu không khớp."""
    return _ctx.verify(plain, hashed)
