import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

class AnswerFeedbackSheet extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final String? correctAnswerText;
  final VoidCallback onContinue;

  const AnswerFeedbackSheet({
    super.key,
    required this.isCorrect,
    required this.explanation,
    this.correctAnswerText,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect
        ? AppColors.primaryLight
        : const Color(0xFFFFECEB);
    final primaryColor = isCorrect ? AppColors.primaryDark : AppColors.error;
    final iconData = isCorrect ? LucideIcons.circleCheck : LucideIcons.circleX;
    final titleText = isCorrect ? 'Tuyệt vời!' : 'Chưa chính xác';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(iconData, color: primaryColor, size: 32),
              const SizedBox(width: 12),
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!isCorrect && correctAnswerText != null) ...[
            Text(
              'Đáp án đúng:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              correctAnswerText!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            explanation,
            style: TextStyle(
              fontSize: 14,
              color: isCorrect
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              elevation: 0,
            ),
            child: Text(
              isCorrect ? 'TIẾP TỤC' : 'ĐÃ HIỂU',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
