"""
app/core/security/password.py

Bcrypt password hashing — sử dụng trực tiếp thư viện bcrypt chuẩn.
Không bao giờ lưu plain text password.
"""

from __future__ import annotations

import bcrypt


def hash_password(plain: str) -> str:
    """Hash password bằng bcrypt."""
    pw_bytes = plain.encode("utf-8")[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pw_bytes, salt).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """So sánh plain password với hashed. Trả False nếu không khớp."""
    if not hashed:
        return False
    pw_bytes = plain.encode("utf-8")[:72]
    try:
        return bcrypt.checkpw(pw_bytes, hashed.encode("utf-8"))
    except Exception:
        return False
