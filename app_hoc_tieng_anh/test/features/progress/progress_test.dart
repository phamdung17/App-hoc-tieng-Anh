import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/features/progress/data/progress_repository.dart';
import 'package:app_hoc_tieng_anh/features/progress/domain/progress_models.dart';

void main() {
  group('ProgressModels Serialization & Parsing Tests', () {
    test('DailySummary parses valid JSON correctly', () {
      final json = {
        'date': '2026-11-08',
        'xp_earned': 25,
        'lessons_completed': 2,
        'minutes_studied': 10,
        'has_activity': true,
      };

      final summary = DailySummary.fromJson(json);

      expect(summary.dateString, '2026-11-08');
      expect(summary.xpEarned, 25);
      expect(summary.lessonsCompleted, 2);
      expect(summary.minutesStudied, 10);
      expect(summary.hasActivity, isTrue);

      final exported = summary.toJson();
      expect(exported['date'], '2026-11-08');
      expect(exported['xp_earned'], 25);
    });

    test('DailySummary handles missing or malformed fields safely', () {
      final json = <String, dynamic>{};
      final summary = DailySummary.fromJson(json);

      expect(summary.xpEarned, 0);
      expect(summary.lessonsCompleted, 0);
      expect(summary.minutesStudied, 0);
      expect(summary.hasActivity, isFalse);
    });

    test('ProgressSummary parses valid JSON correctly', () {
      final json = {
        'xp_total': 120,
        'streak_days': 5,
        'last_activity_date': '2026-11-08',
        'today_xp': 20,
        'today_lessons': 2,
        'today_minutes': 8,
        'daily_goal_xp': 10,
        'daily_goal_reached': true,
      };

      final summary = ProgressSummary.fromJson(json);

      expect(summary.xpTotal, 120);
      expect(summary.streakDays, 5);
      expect(summary.lastActivityDate, '2026-11-08');
      expect(summary.todayXp, 20);
      expect(summary.todayLessons, 2);
      expect(summary.todayMinutes, 8);
      expect(summary.dailyGoalXp, 10);
      expect(summary.dailyGoalReached, isTrue);
    });

    test('CalendarProgress parses days array correctly', () {
      final json = {
        'days': [
          {
            'date': '2026-11-08',
            'xp_earned': 15,
            'lessons_completed': 1,
            'minutes_studied': 5,
            'has_activity': true,
          },
          {
            'date': '2026-11-07',
            'xp_earned': 0,
            'lessons_completed': 0,
            'minutes_studied': 0,
            'has_activity': false,
          },
        ],
        'total_days_studied': 1,
        'current_streak': 1,
        'longest_streak': 3,
      };

      final calendar = CalendarProgress.fromJson(json);

      expect(calendar.days.length, 2);
      expect(calendar.totalDaysStudied, 1);
      expect(calendar.currentStreak, 1);
      expect(calendar.longestStreak, 3);
      expect(calendar.days.first.xpEarned, 15);
      expect(calendar.days.last.hasActivity, isFalse);
    });
  });

  group('ProgressRepository Fallback Tests', () {
    test('getSummary returns valid ProgressSummary without throwing', () async {
      final repo = ProgressRepository.instance;
      final summary = await repo.getSummary();

      expect(summary, isNotNull);
      expect(summary.dailyGoalXp, greaterThan(0));
      expect(summary.xpTotal, greaterThanOrEqualTo(0));
      expect(summary.streakDays, greaterThanOrEqualTo(0));
    });

    test('getCalendar returns 30 days history by default', () async {
      final repo = ProgressRepository.instance;
      final calendar = await repo.getCalendar(days: 30);

      expect(calendar, isNotNull);
      expect(calendar.days.length, 30);
      expect(calendar.totalDaysStudied, greaterThanOrEqualTo(0));
      expect(calendar.longestStreak, greaterThanOrEqualTo(0));
    });
  });
}

