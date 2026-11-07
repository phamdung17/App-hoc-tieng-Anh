// lib/features/progress/presentation/widgets/streak_milestone_card.dart
//
// Card động lực chuỗi ngày học liên tục (Streak Milestones & Motivation).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

class StreakMilestoneCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakMilestoneCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  // Tính milestone tiếp theo (3, 7, 14, 30, 50, 100 ngày)
  int get _nextMilestone {
    const milestones = [3, 7, 14, 30, 50, 100, 365];
    for (final m in milestones) {
      if (currentStreak < m) return m;
    }
    return currentStreak + 10;
  }

  double get _progressToMilestone {
    final next = _nextMilestone;
    if (next <= 0) return 1.0;
    return (currentStreak / next).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF8E53),
            Color(0xFFFF6200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6200).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.flame,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentStreak Ngày Liên Tiếp',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kỷ lục dài nhất: $longestStreak ngày',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Milestone progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu kế tiếp: $_nextMilestone ngày',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(_progressToMilestone * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressToMilestone,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentStreak > 0
                ? 'Tuyệt vời! Hãy tiếp tục học bài hôm nay để giữ vững ngọn lửa này! 🔥'
                : 'Bắt đầu bài học đầu tiên hôm nay để thắp sáng chuỗi streak của bạn nhé! 🚀',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

