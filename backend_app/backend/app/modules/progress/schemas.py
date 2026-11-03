"""
app/modules/progress/schemas.py

Pydantic schemas cho Progress module.
"""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel

# ── Hằng số MVP ───────────────────────────────────────────────────────────────
DAILY_GOAL_XP: int = 10


class DailySummary(BaseModel):
    """Tóm tắt hoạt động của một ngày cụ thể."""

    date: str                  # "YYYY-MM-DD"
    xp_earned: int
    lessons_completed: int
    minutes_studied: int
    has_activity: bool         # shortcut: xp_earned > 0


class ProgressSummaryResponse(BaseModel):
    """Tóm tắt tiến trình tổng thể của user hiện tại."""

    # Gamification header
    xp_total: int
    streak_days: int
    last_activity_date: Optional[str]   # "YYYY-MM-DD" hoặc null

    # Hôm nay
    today_xp: int
    today_lessons: int
    today_minutes: int

    # Mục tiêu ngày (hardcode 10 XP/ngày cho MVP)
    daily_goal_xp: int          # = DAILY_GOAL_XP
    daily_goal_reached: bool


class CalendarResponse(BaseModel):
    """Lịch học 30 ngày gần nhất (từ today về trước)."""

    days: list[DailySummary]          # danh sách days ngày, mới nhất trước
    total_days_studied: int           # số ngày có activity trong khoảng days
    current_streak: int               # chuỗi liên tiếp từ hôm nay về trước
    longest_streak: int               # chuỗi dài nhất trong khoảng days ngày
