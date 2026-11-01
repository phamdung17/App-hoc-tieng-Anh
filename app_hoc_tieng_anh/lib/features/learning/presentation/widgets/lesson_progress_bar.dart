import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LessonProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final VoidCallback onClose;
  final int hearts;

  const LessonProgressBar({
    super.key,
    required this.progress,
    required this.onClose,
    this.hearts = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 28, color: AppColors.textSecondary),
            tooltip: 'Thoát bài học',
          ),
          const SizedBox(width: 8),

          // Linear animated progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 14,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Hearts / Lives
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.coral, size: 22),
              const SizedBox(width: 4),
              Text(
                '$hearts',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
