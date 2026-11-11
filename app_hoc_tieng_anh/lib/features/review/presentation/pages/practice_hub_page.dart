import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../scan/data/scan_api_service.dart';

/// Giao diện 16 – Trung tâm ôn tập
/// Dashboard gồm: Từ đến hạn SRS, luyện nghe/nói nhanh, flashcard, hộp lỗi sai.
class PracticeHubPage extends StatefulWidget {
  const PracticeHubPage({super.key});

  @override
  State<PracticeHubPage> createState() => _PracticeHubPageState();
}

class _PracticeHubPageState extends State<PracticeHubPage> {
  List<Map<String, dynamic>> _savedWords = const [];
  int _savedWordsCount = 0;
  int _dueTodayCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final words = await ScanApiService.instance.getSavedWords();
      if (mounted) {
        setState(() {
          _savedWords = words;
          _savedWordsCount = words.length;
          _dueTodayCount = words.isNotEmpty
              ? (words.length > 5 ? 5 : words.length)
              : 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedWords = const [];
          _savedWordsCount = 0;
          _dueTodayCount = 0;
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
          'Ôn tập',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── 1. Banner ôn tập hôm nay ───────────────────────────────────
          _DueTodayBanner(
            dueCount: _dueTodayCount,
            isLoading: _isLoading,
            onStart: () => context.go(AppRoutes.flashcards),
          ),

          const SizedBox(height: 20),

          // ── 2. Lối tắt nhanh ──────────────────────────────────────────
          const Text(
            'Luyện tập nhanh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _QuickPracticeCard(
                  icon: LucideIcons.layers,
                  label: 'Flashcard',
                  subtitle: '$_savedWordsCount từ đã lưu',
                  color: AppColors.primary,
                  onTap: () => context.go(AppRoutes.flashcards),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickPracticeCard(
                  icon: LucideIcons.volume2,
                  label: 'Luyện nghe',
                  subtitle: 'Luyện nhận diện âm nhanh',
                  color: const Color(0xFF7C3AED),
                  onTap: () => _showComingSoon(context, 'Luyện nghe nhanh'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _QuickPracticeCard(
                  icon: LucideIcons.mic,
                  label: 'Luyện nói',
                  subtitle: 'Phản xạ phát âm',
                  color: const Color(0xFF059669),
                  onTap: () => _showComingSoon(context, 'Luyện nói nhanh'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickPracticeCard(
                  icon: LucideIcons.brain,
                  label: 'Quiz từ vựng',
                  subtitle: 'Kiểm tra trí nhớ',
                  color: const Color(0xFFD97706),
                  onTap: () => context.go(AppRoutes.flashcards),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── 3. Từ đã lưu để ôn ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Từ đã lưu để ôn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_savedWordsCount từ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_savedWords.isEmpty)
            _EmptySavedWords(onScan: () => context.push(AppRoutes.scan))
          else
            ..._savedWords
                .take(8)
                .map(
                  (word) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SavedWordCard(word: word),
                  ),
                ),

          const SizedBox(height: 16),

          if (_savedWords.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.flashcards),
                icon: const Icon(LucideIcons.refreshCcw, size: 18),
                label: const Text('Ôn lại từ đã lưu'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sẽ khả dụng sau khi kết nối backend.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Widget: Banner ôn tập hôm nay ──────────────────────────────────────────

class _DueTodayBanner extends StatelessWidget {
  final int dueCount;
  final bool isLoading;
  final VoidCallback onStart;
  const _DueTodayBanner({
    required this.dueCount,
    required this.isLoading,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.panel),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Từ cần ôn hôm nay',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? 'Đang tải…' : '$dueCount từ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ôn ngay để không quên — SRS tự động lên lịch.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isLoading ? null : onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size(112, 48),
              maximumSize: const Size(112, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Bắt đầu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Lối tắt luyện nhanh ────────────────────────────────────────────

class _QuickPracticeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickPracticeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget: Thẻ câu sai ────────────────────────────────────────────────────

class _SavedWordCard extends StatelessWidget {
  final Map<String, dynamic> word;
  const _SavedWordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.bookOpen,
                size: 13,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  (word['pos'] as String?) ?? 'Từ vựng đã lưu',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            (word['label'] as String?) ?? 'Từ vựng',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 6),
          Text(
            (word['meaning_vi'] as String?)?.trim().isNotEmpty == true
                ? word['meaning_vi'] as String
                : 'Chạm “Flashcard” để tự kiểm tra từ này.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Trạng thái rỗng ────────────────────────────────────────────────

class _EmptySavedWords extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptySavedWords({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.partyPopper,
            size: 36,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có từ nào trong danh sách ôn tập.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quét ảnh và lưu từ mới, chúng sẽ xuất hiện ở đây.',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(LucideIcons.camera),
            label: const Text('Quét từ mới'),
          ),
        ],
      ),
    );
  }
}
