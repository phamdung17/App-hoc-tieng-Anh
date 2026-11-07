// lib/features/progress/presentation/widgets/daily_goal_card.dart
//
// Card mục tiêu học tập ngày (XP, Bài học hoàn thành, Thời gian học).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/progress_models.dart';

class DailyGoalCard extends StatelessWidget {
  final ProgressSummary summary;

  const DailyGoalCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final targetXp = summary.dailyGoalXp > 0 ? summary.dailyGoalXp : 10;
    final progress = (summary.todayXp / targetXp).clamp(0.0, 1.0);
    final isReached = summary.dailyGoalReached || summary.todayXp >= targetXp;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isReached
                      ? AppColors.primaryLight
                      : AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReached ? LucideIcons.trophy : LucideIcons.target,
                  color: isReached ? AppColors.primaryDark : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mục tiêu hôm nay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isReached
                          ? 'Đã hoàn thành xuất sắc! 🎉'
                          : 'Cần thêm ${targetXp - summary.todayXp} XP để đạt mục tiêu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isReached
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${summary.todayXp}/$targetXp XP',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFFE8ECEB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isReached ? AppColors.primary : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(
                icon: LucideIcons.bookCheck,
                color: AppColors.primaryDark,
                label: 'Bài học',
                value: '${summary.todayLessons} bài',
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              _MetricItem(
                icon: LucideIcons.timer,
                color: AppColors.info,
                label: 'Thời gian',
                value: '${summary.todayMinutes} phút',
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              _MetricItem(
                icon: LucideIcons.zap,
                color: AppColors.warning,
                label: 'XP hôm nay',
                value: '+${summary.todayXp} XP',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

