import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LearningPage extends StatelessWidget {
  final VoidCallback onStartChallenge;

  const LearningPage({super.key, required this.onStartChallenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lộ trình học')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Xin chào! 👋',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Dành vài phút hôm nay để tiến gần hơn tới mục tiêu tiếng Anh của bạn.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, Color(0xFFF4FBF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primaryDark,
                  size: 34,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thử thách từ vựng hôm nay',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trả lời 5 câu hỏi nhanh và xem bạn nhớ được bao nhiêu từ.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onStartChallenge,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Bắt đầu thử thách'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
