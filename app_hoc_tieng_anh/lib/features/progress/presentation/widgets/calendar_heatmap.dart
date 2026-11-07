// lib/features/progress/presentation/widgets/calendar_heatmap.dart
//
// Widget biểu đồ nhiệt (Activity Heatmap) hiển thị lịch học tập 30 ngày:
// - Ô màu theo cấp độ XP (0, 1-9, 10-19, 20+).
// - Hiển thị thứ trong tuần (T2 -> CN).
// - Tương tác chạm vào ô để xem chi tiết hoạt động trong ngày.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/progress_models.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<DailySummary> days;
  final ValueChanged<DailySummary>? onDaySelected;

  const CalendarHeatmap({
    super.key,
    required this.days,
    this.onDaySelected,
  });

  Color _getCellColor(int xp) {
    if (xp <= 0) return const Color(0xFFE8ECEB);
    if (xp < 10) return const Color(0xFFBCEEE1);
    if (xp < 25) return AppColors.primary;
    return AppColors.primaryDark;
  }

  void _showDayDetails(BuildContext context, DailySummary day) {
    final now = DateTime.now();
    final isToday = day.date.year == now.year &&
        day.date.month == now.month &&
        day.date.day == now.day;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: day.hasActivity
                          ? AppColors.primaryLight
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      day.hasActivity
                          ? LucideIcons.calendarCheck
                          : LucideIcons.calendarX,
                      color: day.hasActivity
                          ? AppColors.primaryDark
                          : AppColors.textHint,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}/${day.date.year}'
                          '${isToday ? ' (Hôm nay)' : ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.hasActivity
                              ? 'Đã ghi nhận hoạt động học tập'
                              : 'Chưa có hoạt động học trong ngày này',
                          style: TextStyle(
                            fontSize: 13,
                            color: day.hasActivity
                                ? AppColors.success
                                : AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailStatItem(
                      icon: LucideIcons.zap,
                      iconColor: AppColors.warning,
                      label: 'XP Đạt được',
                      value: '+${day.xpEarned} XP',
                    ),
                    Container(width: 1, height: 36, color: AppColors.divider),
                    _DetailStatItem(
                      icon: LucideIcons.bookOpen,
                      iconColor: AppColors.primaryDark,
                      label: 'Bài hoàn thành',
                      value: '${day.lessonsCompleted} bài',
                    ),
                    Container(width: 1, height: 36, color: AppColors.divider),
                    _DetailStatItem(
                      icon: LucideIcons.clock,
                      iconColor: AppColors.info,
                      label: 'Thời gian học',
                      value: '${day.minutesStudied} phút',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sắp xếp theo thứ tự ngày tăng dần (từ quá khứ đến hôm nay) để hiển thị lịch tự nhiên
    final sortedDays = List<DailySummary>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                LucideIcons.calendarDays,
                size: 20,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 8),
              const Text(
                'Lịch sử học tập (30 ngày)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${days.where((d) => d.hasActivity).length} ngày đã học',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lưới các ngày (7 cột cho 7 ngày trong tuần)
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 7;
              final cellSize = ((constraints.maxWidth - (columns - 1) * 8) / columns)
                  .clamp(28.0, 44.0);

              // Danh sách thứ trong tuần
              const weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

              return Column(
                children: [
                  // Row tiêu đề thứ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekLabels.map((label) {
                      return SizedBox(
                        width: cellSize,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Lưới ngày
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedDays.map((day) {
                      final isToday = day.date.year == now.year &&
                          day.date.month == now.month &&
                          day.date.day == now.day;

                      return GestureDetector(
                        onTap: () {
                          if (onDaySelected != null) {
                            onDaySelected!(day);
                          }
                          _showDayDetails(context, day);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: _getCellColor(day.xpEarned),
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(
                                    color: AppColors.coral,
                                    width: 2,
                                  )
                                : Border.all(
                                    color: Colors.black.withValues(alpha: 0.04),
                                  ),
                          ),
                          child: Center(
                            child: Text(
                              day.date.day.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.w900
                                    : (day.hasActivity
                                        ? FontWeight.w700
                                        : FontWeight.w500),
                                color: day.xpEarned >= 25
                                    ? Colors.white
                                    : (day.hasActivity
                                        ? AppColors.textPrimary
                                        : AppColors.textHint),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Chú thích thang màu (Legend)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Ít',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              const SizedBox(width: 6),
              _LegendBox(color: const Color(0xFFE8ECEB)),
              const SizedBox(width: 4),
              _LegendBox(color: const Color(0xFFBCEEE1)),
              const SizedBox(width: 4),
              _LegendBox(color: AppColors.primary),
              const SizedBox(width: 4),
              _LegendBox(color: AppColors.primaryDark),
              const SizedBox(width: 6),
              const Text(
                'Nhiều XP',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendBox extends StatelessWidget {
  final Color color;
  const _LegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DetailStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailStatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
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

