import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VocabularyPage extends StatelessWidget {
  const VocabularyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vocabList = [
      {'word': 'Coffee Cup', 'ipa': '/ˈkɒf.i kʌp/', 'vi': 'Cốc cà phê', 'tag': 'AI Scan', 'emoji': '☕'},
      {'word': 'Notebook', 'ipa': '/ˈnəʊt.bʊk/', 'vi': 'Quyển sổ tay', 'tag': 'AI Scan', 'emoji': '📖'},
      {'word': 'Student', 'ipa': '/ˈstjuː.dənt/', 'vi': 'Học sinh, sinh viên', 'tag': 'Bài học', 'emoji': '🧑‍🎓'},
      {'word': 'Apple', 'ipa': '/ˈæp.əl/', 'vi': 'Quả táo', 'tag': 'Từ mới', 'emoji': '🍎'},
      {'word': 'Laptop', 'ipa': '/ˈlæp.tɒp/', 'vi': 'Máy tính xách tay', 'tag': 'AI Scan', 'emoji': '💻'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kho từ vựng cá nhân', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Tìm kiếm từ',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vocabList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = vocabList[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(item['emoji']!, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['word']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['tag']!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['ipa']} • ${item['vi']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phát âm "${item['word']}"'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.volume_up_rounded, color: AppColors.primaryDark),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
