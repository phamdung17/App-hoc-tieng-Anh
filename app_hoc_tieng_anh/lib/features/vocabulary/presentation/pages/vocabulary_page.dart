// lib/features/vocabulary/presentation/pages/vocabulary_page.dart
//
// Màn hình Quản lý Từ vựng & Tra cứu Từ điển hệ thống:
// - Tab 1: Từ vựng cá nhân đã lưu (Saved Words từ AI Camera Scan)
// - Tab 2: Từ điển hệ thống (Catalog) tích hợp VocabularyApiService:
//   * Tìm kiếm từ theo từ vựng hoặc nghĩa
//   * Lọc theo chủ đề (Topics)
//   * Phân trang và tra cứu chi tiết

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/network/app_api.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/vocabulary_api_service.dart';
import '../../domain/vocabulary_word.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Tab 1: Saved words state ───────────────────────────────────────────────
  late Future<List<VocabularyWord>> _savedWordsFuture = _loadSavedWords();

  // ── Tab 2: Catalog state ───────────────────────────────────────────────────
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<String> _topics = [];
  String _selectedTopic = '';
  List<VocabularyWord> _catalogWords = [];
  bool _isLoadingCatalog = false;
  String? _catalogError;
  int _catalogTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTopics();
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ── Tab 1 Logic ────────────────────────────────────────────────────────────

  Future<List<VocabularyWord>> _loadSavedWords() async {
    final response = await AppApi.instance.dio.get<List<dynamic>>(
      '/scans/saved-words',
    );
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VocabularyWord.fromApi)
        .toList(growable: false);
  }

  // ── Tab 2 Logic ────────────────────────────────────────────────────────────

  Future<void> _loadTopics() async {
    try {
      final topics = await VocabularyApiService.instance.listTopics();
      if (mounted) {
        setState(() => _topics = topics);
      }
    } catch (_) {}
  }

  Future<void> _loadCatalog({String? search, String? topic}) async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    try {
      final result = await VocabularyApiService.instance.listWords(
        search: search ?? _searchController.text.trim(),
        topic: topic ?? (_selectedTopic.isNotEmpty ? _selectedTopic : null),
        pageSize: 50,
      );

      if (mounted) {
        setState(() {
          _catalogWords = result.items;
          _catalogTotal = result.total;
          _isLoadingCatalog = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _catalogError = 'Không thể tải danh mục từ điển. Vui lòng thử lại!';
          _isLoadingCatalog = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _loadCatalog(search: query);
    });
  }

  void _onTopicSelected(String topic) {
    final newTopic = _selectedTopic == topic ? '' : topic;
    setState(() => _selectedTopic = newTopic);
    _loadCatalog(topic: newTopic.isNotEmpty ? newTopic : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kho từ vựng & Từ điển',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.bookmark, size: 18),
              text: 'Đã lưu (AI Scan)',
            ),
            Tab(
              icon: Icon(LucideIcons.library, size: 18),
              text: 'Từ điển hệ thống',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSavedWordsTab(), _buildCatalogTab()],
      ),
    );
  }

  // ── Tab 1: Saved Words View ────────────────────────────────────────────────

  Widget _buildSavedWordsTab() {
    return FutureBuilder<List<VocabularyWord>>(
      future: _savedWordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.cloudOff,
                    size: 44,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không tải được từ đã lưu. Kiểm tra kết nối rồi thử lại.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _savedWordsFuture = _loadSavedWords()),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final words = snapshot.data ?? const <VocabularyWord>[];
        if (words.isEmpty) {
          return const _EmptySavedVocabulary();
        }

        return RefreshIndicator(
          onRefresh: () async {
            final future = _loadSavedWords();
            setState(() {
              _savedWordsFuture = future;
            });
            await future;
          },
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: words.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _VocabularyTile(word: words[index]),
          ),
        );
      },
    );
  }

  // ── Tab 2: Catalog View ────────────────────────────────────────────────────

  Widget _buildCatalogTab() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm từ vựng hoặc nghĩa...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(
                LucideIcons.search,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadCatalog(search: '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.input),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Topic chips
        if (_topics.isNotEmpty)
          Container(
            height: 48,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TopicFilterChip(
                  label: 'Tất cả',
                  isSelected: _selectedTopic.isEmpty,
                  onTap: () => _onTopicSelected(''),
                ),
                const SizedBox(width: 8),
                ..._topics.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TopicFilterChip(
                      label: _formatTopicName(t),
                      isSelected: _selectedTopic == t,
                      onTap: () => _onTopicSelected(t),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1, color: AppColors.divider),

        // Catalog word count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            'Hiển thị ${_catalogWords.length} / $_catalogTotal từ vựng',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // Catalog list
        Expanded(child: _buildCatalogList()),
      ],
    );
  }

  Widget _buildCatalogList() {
    if (_isLoadingCatalog && _catalogWords.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_catalogError != null && _catalogWords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 40,
                color: AppColors.warning,
              ),
              const SizedBox(height: 12),
              Text(
                _catalogError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadCatalog(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_catalogWords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Không tìm thấy từ vựng phù hợp.',
            style: TextStyle(color: AppColors.textHint, fontSize: 14),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCatalog(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _catalogWords.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _VocabularyTile(word: _catalogWords[index]),
      ),
    );
  }

  String _formatTopicName(String topic) {
    switch (topic.toLowerCase()) {
      case 'greeting':
        return 'Chào hỏi';
      case 'food':
        return 'Ẩm thực';
      case 'travel':
        return 'Du lịch';
      case 'daily':
        return 'Hàng ngày';
      default:
        return topic[0].toUpperCase() + topic.substring(1);
    }
  }
}

// ── Widget components ────────────────────────────────────────────────────────

class _TopicFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isSelected ? AppColors.primary : AppColors.background,
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : AppColors.outline.withValues(alpha: 0.15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _VocabularyTile extends StatelessWidget {
  const _VocabularyTile({required this.word});
  final VocabularyWord word;

  @override
  Widget build(BuildContext context) {
    final isCatalog = word.source == 'Catalog';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: () => context.push('/word/${word.id}', extra: word),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.outline.withValues(alpha: .1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCatalog
                      ? AppColors.primaryLight
                      : const Color(0xFFFFF0ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCatalog ? LucideIcons.bookOpen : LucideIcons.camera,
                  color: isCatalog ? AppColors.primaryDark : AppColors.coral,
                  size: 20,
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
                        if (word.partOfSpeech.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${word.partOfSpeech})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _SourceTag(label: word.source),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${word.ipa.isNotEmpty ? "${word.ipa} · " : ""}${word.meaningVi}',
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
    final isCatalog = label == 'Catalog';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCatalog ? AppColors.primaryLight : const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isCatalog ? AppColors.primaryDark : AppColors.coral,
        ),
      ),
    );
  }
}

class _EmptySavedVocabulary extends StatelessWidget {
  const _EmptySavedVocabulary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.bookmarkCheck,
              size: 44,
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có từ nào được lưu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chụp ảnh quét vật thể bằng AI hoặc khám phá từ điển hệ thống để thêm vào kho từ nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => context.push('/scan'),
              icon: const Icon(LucideIcons.camera, size: 18),
              label: const Text('Quét từ mới ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
}
