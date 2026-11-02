import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/mock_vocabulary_repository.dart';
import '../../domain/vocabulary_word.dart';

class VocabularyDetailPage extends StatefulWidget {
  const VocabularyDetailPage({super.key, required this.wordId, this.word});

  final String wordId;
  final VocabularyWord? word;

  @override
  State<VocabularyDetailPage> createState() => _VocabularyDetailPageState();
}

class _VocabularyDetailPageState extends State<VocabularyDetailPage> {
  final _repository = MockVocabularyRepository.instance;
  late VocabularyWord? _word;

  @override
  void initState() {
    super.initState();
    _word = _repository.getById(widget.wordId) ?? widget.word;
  }

  Future<void> _editNote() async {
    final word = _word;
    if (word == null) return;
    final controller = TextEditingController(text: word.note);
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
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
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ghi chú cá nhân',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Viết một ghi chú giúp bạn nhớ từ này...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(sheetContext).pop(controller.text),
              child: const Text('Lưu ghi chú'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || note == null) return;
    _repository.updateNote(word.id, note);
    setState(() => _word = _repository.getById(word.id));
  }

  Future<void> _deleteWord() async {
    final word = _word;
    if (word == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa từ khỏi kho?'),
        content: Text(
          '“${word.word}” sẽ bị xóa khỏi danh sách từ đã lưu trên thiết bị này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa từ'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    _repository.delete(word.id);
    context.go(AppRoutes.vocabulary);
  }

  @override
  Widget build(BuildContext context) {
    final word = _word;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Chi tiết từ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (word != null)
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn từ',
              onSelected: (value) {
                if (value == 'edit') _editNote();
                if (value == 'delete') _deleteWord();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(LucideIcons.pencil),
                    title: Text('Sửa ghi chú'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(LucideIcons.trash2, color: AppColors.error),
                    title: Text('Xóa từ'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: word == null ? const _WordNotFound() : _buildDetails(word),
      bottomNavigationBar: word == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.review),
                  icon: const Icon(LucideIcons.bookOpen),
                  label: const Text('Ôn tập từ này'),
                ),
              ),
            ),
    );
  }

  Widget _buildDetails(VocabularyWord word) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.outline, width: 1.25),
            boxShadow: const [
              BoxShadow(color: AppColors.outline, offset: Offset(3, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Tag(
                    label: word.topic,
                    background: AppColors.primaryLight,
                    foreground: AppColors.primaryDark,
                  ),
                  const Spacer(),
                  _Tag(
                    label: word.partOfSpeech,
                    background: const Color(0xFFFFE5DC),
                    foreground: AppColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                word.word,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word.ipa,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Phát âm',
                    onPressed: () => _showPronunciationNotice(word),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    icon: const Icon(LucideIcons.volume2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              const _SectionLabel(label: 'Nghĩa tiếng Việt'),
              const SizedBox(height: 6),
              Text(
                word.meaningVi,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: LucideIcons.bookOpen,
          title: 'Ví dụ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word.exampleEn,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                word.exampleVi,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: LucideIcons.notebookPen,
          title: 'Ghi chú của bạn',
          trailing: TextButton.icon(
            onPressed: _editNote,
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: Text(word.note.isEmpty ? 'Thêm' : 'Sửa'),
          ),
          child: Text(
            word.note.isEmpty
                ? 'Thêm ghi chú hoặc mẹo ghi nhớ cho từ này.'
                : word.note,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: word.note.isEmpty
                  ? AppColors.textHint
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              LucideIcons.bookmark,
              size: 17,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 8),
            Text(
              'Được lưu từ ${word.source}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPronunciationNotice(VocabularyWord word) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Dịch vụ phát âm chưa được kết nối cho “${word.word}”.',
          ),
        ),
      );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textHint,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WordNotFound extends StatelessWidget {
  const _WordNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.circleAlert,
              size: 42,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy từ này',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Từ có thể đã bị xóa khỏi kho từ vựng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.vocabulary),
              child: const Text('Về kho từ vựng'),
            ),
          ],
        ),
      ),
    );
  }
}
