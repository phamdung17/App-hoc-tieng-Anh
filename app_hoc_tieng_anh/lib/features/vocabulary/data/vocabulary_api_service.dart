import '../../../core/network/app_api.dart';
import '../domain/vocabulary_word.dart';

/// Gọi endpoints GET /vocab — lấy danh sách và chi tiết từ vựng từ backend.
class VocabularyApiService {
  VocabularyApiService._();
  static final instance = VocabularyApiService._();

  final _api = AppApi.instance;

  // ── Danh sách từ (có phân trang + filter) ──────────────────────────────────

  Future<VocabListResult> listWords({
    String? topic,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _api.dio.get<Map<String, dynamic>>(
      '/vocab',
      queryParameters: queryParams,
    );
    final data = response.data ?? const {};
    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VocabularyWord.fromWordApi)
        .toList(growable: false);

    return VocabListResult(
      items: items,
      total: (data['total'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? page,
      pageSize: (data['page_size'] as num?)?.toInt() ?? pageSize,
      hasNext: data['has_next'] as bool? ?? false,
    );
  }

  // ── Danh sách chủ đề ───────────────────────────────────────────────────────

  Future<List<String>> listTopics() async {
    final response = await _api.dio.get<List<dynamic>>('/vocab/topics');
    return (response.data ?? const []).whereType<String>().toList();
  }

  // ── Chi tiết từ theo ID ────────────────────────────────────────────────────

  Future<VocabularyWord> getById(String wordId) async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/vocab/$wordId');
    return VocabularyWord.fromWordApi(response.data ?? const {});
  }

  // ── Chi tiết từ theo lemma ─────────────────────────────────────────────────

  Future<VocabularyWord?> getByLemma(String lemma) async {
    try {
      final response = await _api.dio
          .get<Map<String, dynamic>>('/vocab/lemma/$lemma');
      return VocabularyWord.fromWordApi(response.data ?? const {});
    } catch (_) {
      return null;
    }
  }
}

/// Kết quả phân trang từ API /vocab
class VocabListResult {
  const VocabListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasNext,
  });

  final List<VocabularyWord> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasNext;
}

