// lib/features/progress/presentation/widgets/progress_stats_row.dart
//
// 4 Ô thống kê tổng quan (Tổng XP, Chuỗi streak, Tổng ngày đã học, Kỷ lục streak).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/progress_models.dart';

class ProgressStatsRow extends StatelessWidget {
  final ProgressSummary summary;
  final CalendarProgress calendar;

  const ProgressStatsRow({
    super.key,
    required this.summary,
    required this.calendar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.zap,
            iconColor: AppColors.warning,
            bgColor: AppColors.warning.withValues(alpha: 0.1),
            value: '${summary.xpTotal}',
            label: 'Tổng XP',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.flame,
            iconColor: AppColors.coral,
            bgColor: AppColors.coral.withValues(alpha: 0.1),
            value: '${summary.streakDays}',
            label: 'Streak ngày',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.calendarCheck2,
            iconColor: AppColors.primaryDark,
            bgColor: AppColors.primaryLight,
            value: '${calendar.totalDaysStudied}',
            label: 'Ngày đã học',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.award,
            iconColor: const Color(0xFF8E44AD),
            bgColor: const Color(0xFF8E44AD).withValues(alpha: 0.1),
            value: '${calendar.longestStreak}',
            label: 'Kỷ lục Streak',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

