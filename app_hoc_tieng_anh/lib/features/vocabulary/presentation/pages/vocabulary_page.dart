import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/app_api.dart';
import '../../domain/vocabulary_word.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  late Future<List<VocabularyWord>> _words = _loadWords();

  Future<List<VocabularyWord>> _loadWords() async {
    final response = await AppApi.instance.dio.get<List<dynamic>>('/scans/saved-words');
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VocabularyWord.fromApi)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kho từ vựng cá nhân',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
          onPressed: () => setState(() => _words = _loadWords()),
            icon: const Icon(LucideIcons.search),
            tooltip: 'Tìm kiếm từ',
          ),
        ],
      ),
      body: FutureBuilder<List<VocabularyWord>>(
        future: _words,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Không tải được kho từ. Hãy đăng nhập rồi thử lại.'),
                TextButton(onPressed: () => setState(() => _words = _loadWords()), child: const Text('Thử lại')),
              ]),
            );
          }
          final words = snapshot.data ?? const <VocabularyWord>[];
          if (words.isEmpty) return const _EmptyVocabulary();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: words.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _VocabularyTile(word: words[index]),
          );
        },
      ),
    );
  }
}

class _VocabularyTile extends StatelessWidget {
  const _VocabularyTile({required this.word});
  final VocabularyWord word;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: () => context.push('/word/${word.id}', extra: word),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.outline.withValues(alpha: .12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .03),
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
                child: const Icon(
                  LucideIcons.bookOpen,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            word.word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SourceTag(label: word.source),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${word.ipa} · ${word.meaningVi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _EmptyVocabulary extends StatelessWidget {
  const _EmptyVocabulary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.bookOpen,
              size: 42,
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: 14),
            const Text(
              'Kho từ đang trống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lưu từ mới khi học hoặc quét vật thể để xem lại tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => context.push('/scan'),
              icon: const Icon(LucideIcons.camera),
              label: const Text('Quét từ mới'),
            ),
          ],
        ),
      ),
    );
  }
}
