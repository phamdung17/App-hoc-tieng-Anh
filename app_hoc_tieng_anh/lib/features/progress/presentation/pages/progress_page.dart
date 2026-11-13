// lib/features/progress/presentation/pages/progress_page.dart
//
// Màn hình Thống kê Tiến độ học tập & Biểu đồ nhiệt hoạt động (Activity Heatmap).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/progress_repository.dart';
import '../../domain/progress_models.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/progress_stats_row.dart';
import '../widgets/streak_milestone_card.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _repository = ProgressRepository.instance;

  ProgressSummary? _summary;
  CalendarProgress? _calendar;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getSummary(),
        _repository.getCalendar(days: 30),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as ProgressSummary;
          _calendar = results[1] as CalendarProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summary = null;
          _calendar = null;
          _errorMessage = 'Không thể tải dữ liệu tiến độ. Vui lòng thử lại!';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tiến độ học tập',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(LucideIcons.rotateCw, size: 20, color: AppColors.textPrimary),
            onPressed: _loadProgress,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _summary == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null && _summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cloudOff, size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadProgress,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 48),
                  maximumSize: const Size(220, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final summary = _summary!;
    final calendar = _calendar!;

    return RefreshIndicator(
      onRefresh: _loadProgress,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Streak Milestone Card
            StreakMilestoneCard(
              currentStreak: summary.streakDays,
              longestStreak: calendar.longestStreak,
            ),
            const SizedBox(height: 16),

            // 2. Daily Goal Progress Card
            DailyGoalCard(summary: summary),
            const SizedBox(height: 16),

            // 3. Stats Overview Row
            ProgressStatsRow(summary: summary, calendar: calendar),
            const SizedBox(height: 16),

            // 4. Activity Calendar Heatmap (30 days)
            CalendarHeatmap(days: calendar.days),
            const SizedBox(height: 20),

            // 5. Quick Action Button to continue learning
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sẵn sàng học tiếp?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hoàn thành thêm bài học để tích lũy XP hôm nay',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.learning),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(96, 44),
                      maximumSize: const Size(132, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Học ngay',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

