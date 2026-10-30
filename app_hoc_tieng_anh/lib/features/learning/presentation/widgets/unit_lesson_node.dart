import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/lesson_models.dart';

class UnitLessonNodeWidget extends StatelessWidget {
  final LessonNode lesson;
  final VoidCallback onTap;

  const UnitLessonNodeWidget({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor;
    Color iconColor;
    IconData icon;
    Widget? badge;

    switch (lesson.status) {
      case LessonStatus.completed:
        nodeColor = const Color(0xFFFFC837);
        iconColor = Colors.white;
        icon = Icons.check_rounded;
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 14, color: Colors.white),
              SizedBox(width: 2),
              Text(
                'Xong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
        break;
      case LessonStatus.current:
        nodeColor = AppColors.primary;
        iconColor = Colors.white;
        icon = Icons.play_arrow_rounded;
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'BẮT ĐẦU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        );
        break;
      case LessonStatus.locked:
        nodeColor = const Color(0xFFE2E8F0);
        iconColor = const Color(0xFF94A3B8);
        icon = Icons.lock_rounded;
        badge = null;
        break;
    }

    final isCurrent = lesson.status == LessonStatus.current;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            badge,
            const SizedBox(height: 6),
          ],
          // Circular Node
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCurrent)
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 4,
                    ),
                  ),
                ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isCurrent
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: isCurrent ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: isCurrent ? 36 : 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Title
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              lesson.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: lesson.status == LessonStatus.locked
                    ? AppColors.textHint
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

