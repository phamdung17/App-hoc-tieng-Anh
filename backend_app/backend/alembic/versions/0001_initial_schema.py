"""
alembic/versions/0001_initial_schema.py

Migration đầu tiên — tạo toàn bộ schema từ các models hiện tại:
  - users
  - words
  - scans
  - scan_items

Chạy: alembic upgrade head
"""

from __future__ import annotations

import uuid
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision: str = "0001_initial_schema"
down_revision: str | None = None
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    # ── Extension pgcrypto (gen_random_uuid) ──────────────────────────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")

    # ── users ─────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        # Identity
        sa.Column("email", sa.String(254), nullable=False),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("display_name", sa.String(80), nullable=False, server_default=""),
        sa.Column("avatar_url", sa.String(500), nullable=True),
        # Verification
        sa.Column("email_verified", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("email_verify_token", sa.String(255), nullable=True),
        sa.Column(
            "email_verify_expires_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
        # AI Usage
        sa.Column("ai_scan_count_total", sa.Integer(), nullable=False, server_default="0"),
        # Gamification
        sa.Column("xp_total", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("streak_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_activity_date", sa.DateTime(timezone=True), nullable=True),
        # Status
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("is_guest", sa.Boolean(), nullable=False, server_default="false"),
        # FCM
        sa.Column("fcm_token", sa.String(500), nullable=True),
        # Timestamps
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    # ── words ─────────────────────────────────────────────────────────────────
    op.create_table(
        "words",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        # Core
        sa.Column("lemma", sa.String(50), nullable=False, comment="Base form của từ (lowercase). Duy nhất trong catalog."),
        # Word card
        sa.Column("ipa", sa.String(50), nullable=False, server_default=""),
        sa.Column("pos", sa.String(20), nullable=False, server_default="noun", comment="Part of speech: noun, verb, adj, adv, ..."),
        sa.Column("meaning_vi", sa.Text(), nullable=False, server_default="", comment="Nghĩa tiếng Việt"),
        sa.Column("example_en", sa.Text(), nullable=False, server_default=""),
        sa.Column("example_vi", sa.Text(), nullable=False, server_default=""),
        sa.Column("topic", sa.String(50), nullable=False, server_default="other", comment="Chủ đề: food, animal, furniture, clothing, ..."),
        # Media
        sa.Column("image_url", sa.String(500), nullable=True, comment="Ảnh minh họa từ (public CDN URL)."),
        # Origin
        sa.Column("is_seeded", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("is_ai_generated", sa.Boolean(), nullable=False, server_default="false"),
        # Timestamps
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_words_lemma", "words", ["lemma"], unique=True)

    # ── scans ─────────────────────────────────────────────────────────────────
    op.create_table(
        "scans",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        # Image
        sa.Column("image_key", sa.String(500), nullable=False, comment="Object storage key trong bucket scans-private."),
        sa.Column("image_mime_type", sa.String(50), nullable=False, server_default="image/jpeg"),
        # Status
        sa.Column("status", sa.String(20), nullable=False, server_default="ok", comment="ok | no_object | failed"),
        sa.Column("object_count", sa.Integer(), nullable=False, server_default="0"),
        # AI metadata
        sa.Column("gemini_model", sa.String(50), nullable=False, server_default=""),
        # Timestamps
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_scans_user_id", "scans", ["user_id"])

    # ── scan_items ────────────────────────────────────────────────────────────
    op.create_table(
        "scan_items",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "scan_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("scans.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "word_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("words.id", ondelete="SET NULL"),
            nullable=True,
            comment="Null nếu chưa tra được trong catalog hoặc từ mới chưa save.",
        ),
        # Label
        sa.Column("label", sa.String(50), nullable=False),
        sa.Column("label_vi", sa.String(100), nullable=False, server_default=""),
        sa.Column("confidence", sa.Float(), nullable=False),
        # Word card snapshot (denormalized)
        sa.Column("ipa", sa.String(50), nullable=False, server_default=""),
        sa.Column("pos", sa.String(20), nullable=False, server_default="noun"),
        sa.Column("meaning_vi", sa.Text(), nullable=False, server_default=""),
        sa.Column("example_en", sa.Text(), nullable=False, server_default=""),
        sa.Column("example_vi", sa.Text(), nullable=False, server_default=""),
        sa.Column("topic", sa.String(50), nullable=False, server_default="other"),
        # Bounding box (normalized 0..1)
        sa.Column("bbox_x", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("bbox_y", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("bbox_w", sa.Float(), nullable=False, server_default="1.0"),
        sa.Column("bbox_h", sa.Float(), nullable=False, server_default="1.0"),
        # Crop image
        sa.Column("crop_key", sa.String(500), nullable=True, comment="Object storage key cho ảnh crop của vật thể này."),
        # User actions
        sa.Column("is_saved", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("is_reported", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("user_label_override", sa.String(50), nullable=True, comment="Label user đổi qua PATCH /scan-items/{id}."),
        # Timestamps
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_scan_items_scan_id", "scan_items", ["scan_id"])
    op.create_index("ix_scan_items_word_id", "scan_items", ["word_id"])


def downgrade() -> None:
    op.drop_table("scan_items")
    op.drop_table("scans")
    op.drop_table("words")
    op.drop_table("users")
