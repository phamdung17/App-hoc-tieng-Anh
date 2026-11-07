// lib/features/progress/domain/progress_models.dart
//
// Domain models cho phân hệ thống kê tiến độ học tập (Progress & Streak Heatmap).

class DailySummary {
  final DateTime date;
  final String dateString;
  final int xpEarned;
  final int lessonsCompleted;
  final int minutesStudied;
  final bool hasActivity;

  const DailySummary({
    required this.date,
    required this.dateString,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.minutesStudied,
    required this.hasActivity,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString() ?? '';
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(rawDate);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final xp = (json['xp_earned'] as num?)?.toInt() ?? 0;
    final lessons = (json['lessons_completed'] as num?)?.toInt() ?? 0;
    final minutes = (json['minutes_studied'] as num?)?.toInt() ?? 0;
    final active = json['has_activity'] as bool? ?? (xp > 0);

    return DailySummary(
      date: parsedDate,
      dateString: rawDate,
      xpEarned: xp,
      lessonsCompleted: lessons,
      minutesStudied: minutes,
      hasActivity: active,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': dateString,
    'xp_earned': xpEarned,
    'lessons_completed': lessonsCompleted,
    'minutes_studied': minutesStudied,
    'has_activity': hasActivity,
  };
}

class ProgressSummary {
  final int xpTotal;
  final int streakDays;
  final String? lastActivityDate;
  final int todayXp;
  final int todayLessons;
  final int todayMinutes;
  final int dailyGoalXp;
  final bool dailyGoalReached;

  const ProgressSummary({
    required this.xpTotal,
    required this.streakDays,
    this.lastActivityDate,
    required this.todayXp,
    required this.todayLessons,
    required this.todayMinutes,
    required this.dailyGoalXp,
    required this.dailyGoalReached,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      xpTotal: (json['xp_total'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['last_activity_date']?.toString(),
      todayXp: (json['today_xp'] as num?)?.toInt() ?? 0,
      todayLessons: (json['today_lessons'] as num?)?.toInt() ?? 0,
      todayMinutes: (json['today_minutes'] as num?)?.toInt() ?? 0,
      dailyGoalXp: (json['daily_goal_xp'] as num?)?.toInt() ?? 10,
      dailyGoalReached: json['daily_goal_reached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'xp_total': xpTotal,
    'streak_days': streakDays,
    'last_activity_date': lastActivityDate,
    'today_xp': todayXp,
    'today_lessons': todayLessons,
    'today_minutes': todayMinutes,
    'daily_goal_xp': dailyGoalXp,
    'daily_goal_reached': dailyGoalReached,
  };
}

class CalendarProgress {
  final List<DailySummary> days;
  final int totalDaysStudied;
  final int currentStreak;
  final int longestStreak;

  const CalendarProgress({
    required this.days,
    required this.totalDaysStudied,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory CalendarProgress.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final List<DailySummary> parsedDays = [];
    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is Map<String, dynamic>) {
          parsedDays.add(DailySummary.fromJson(item));
        }
      }
    }

    return CalendarProgress(
      days: parsedDays,
      totalDaysStudied: (json['total_days_studied'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'days': days.map((d) => d.toJson()).toList(),
    'total_days_studied': totalDaysStudied,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
  };
}

