"""Create the initial application schema.

Revision ID: 20261027_0001
Revises:
Create Date: 2026-10-27
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20261027_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("email", sa.String(length=254), nullable=False),
        sa.Column("hashed_password", sa.String(length=255), nullable=False),
        sa.Column("display_name", sa.String(length=80), nullable=False),
        sa.Column("avatar_url", sa.String(length=500), nullable=True),
        sa.Column("email_verified", sa.Boolean(), nullable=False),
        sa.Column("email_verify_token", sa.String(length=255), nullable=True),
        sa.Column("email_verify_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ai_scan_count_total", sa.Integer(), nullable=False),
        sa.Column("xp_total", sa.Integer(), nullable=False),
        sa.Column("streak_days", sa.Integer(), nullable=False),
        sa.Column("last_activity_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("is_guest", sa.Boolean(), nullable=False),
        sa.Column("fcm_token", sa.String(length=500), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "words",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("lemma", sa.String(length=50), nullable=False),
        sa.Column("ipa", sa.String(length=50), nullable=False),
        sa.Column("pos", sa.String(length=20), nullable=False),
        sa.Column("meaning_vi", sa.Text(), nullable=False),
        sa.Column("example_en", sa.Text(), nullable=False),
        sa.Column("example_vi", sa.Text(), nullable=False),
        sa.Column("topic", sa.String(length=50), nullable=False),
        sa.Column("image_url", sa.String(length=500), nullable=True),
        sa.Column("is_seeded", sa.Boolean(), nullable=False),
        sa.Column("is_ai_generated", sa.Boolean(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_words_lemma", "words", ["lemma"], unique=True)

    op.create_table(
        "scans",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("image_key", sa.String(length=500), nullable=False),
        sa.Column("image_mime_type", sa.String(length=50), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("object_count", sa.Integer(), nullable=False),
        sa.Column("gemini_model", sa.String(length=50), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_scans_user_id", "scans", ["user_id"], unique=False)

    op.create_table(
        "scan_items",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("scan_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("word_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("label", sa.String(length=50), nullable=False),
        sa.Column("label_vi", sa.String(length=100), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("ipa", sa.String(length=50), nullable=False),
        sa.Column("pos", sa.String(length=20), nullable=False),
        sa.Column("meaning_vi", sa.Text(), nullable=False),
        sa.Column("example_en", sa.Text(), nullable=False),
        sa.Column("example_vi", sa.Text(), nullable=False),
        sa.Column("topic", sa.String(length=50), nullable=False),
        sa.Column("bbox_x", sa.Float(), nullable=False),
        sa.Column("bbox_y", sa.Float(), nullable=False),
        sa.Column("bbox_w", sa.Float(), nullable=False),
        sa.Column("bbox_h", sa.Float(), nullable=False),
        sa.Column("crop_key", sa.String(length=500), nullable=True),
        sa.Column("is_saved", sa.Boolean(), nullable=False),
        sa.Column("is_reported", sa.Boolean(), nullable=False),
        sa.Column("user_label_override", sa.String(length=50), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["scan_id"], ["scans.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["word_id"], ["words.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_scan_items_scan_id", "scan_items", ["scan_id"], unique=False)
    op.create_index("ix_scan_items_word_id", "scan_items", ["word_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_scan_items_word_id", table_name="scan_items")
    op.drop_index("ix_scan_items_scan_id", table_name="scan_items")
    op.drop_table("scan_items")
    op.drop_index("ix_scans_user_id", table_name="scans")
    op.drop_table("scans")
    op.drop_index("ix_words_lemma", table_name="words")
    op.drop_table("words")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
