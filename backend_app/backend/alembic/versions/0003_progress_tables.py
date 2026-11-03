"""
alembic/versions/0003_progress_tables.py

Migration: tạo bảng user_daily_activities để theo dõi tiến trình học tập.
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers
revision: str = "0003_progress_tables"
down_revision: str = "0002_learning_tables"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    # ── user_daily_activities ─────────────────────────────────────────────
    op.create_table(
        "user_daily_activities",
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
        sa.Column(
            "activity_date",
            sa.Date(),
            nullable=False,
        ),
        sa.Column(
            "xp_earned",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "lessons_completed",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "minutes_studied",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        # Timestamps (TimestampMixin)
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

    # Index trên user_id đơn
    op.create_index(
        "ix_user_daily_activities_user_id",
        "user_daily_activities",
        ["user_id"],
        unique=False,
    )

    # Unique index trên (user_id, activity_date)
    op.create_unique_constraint(
        "uq_user_daily_activities_user_date",
        "user_daily_activities",
        ["user_id", "activity_date"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_user_daily_activities_user_date",
        "user_daily_activities",
        type_="unique",
    )
    op.drop_index("ix_user_daily_activities_user_id", table_name="user_daily_activities")
    op.drop_table("user_daily_activities")
