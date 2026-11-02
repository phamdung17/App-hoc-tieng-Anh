import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

class ExitLessonDialog extends StatelessWidget {
  const ExitLessonDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: const Row(
        children: [
          Icon(LucideIcons.triangleAlert, color: AppColors.warning, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rời khỏi bài học?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
        ],
      ),
      content: const Text(
        'Nếu thoát bây giờ, bạn sẽ bị mất tiến trình câu hỏi của bài học này.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // Confirm exit
          child: const Text(
            'THOÁT',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false), // Stay
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Ở LẠI HỌC TIẾP',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
