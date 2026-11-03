// lib/features/learning/data/learning_api_service.dart
//
// Service gọi API FastAPI cho phân hệ học tập (Learning module):
// - GET /learning/paths
// - GET /learning/paths/{id}
// - GET /learning/lessons/{id}
// - POST /learning/lessons/{id}/submit

import '../../../../core/network/app_api.dart';

class LearningApiService {
  LearningApiService._();
  static final LearningApiService instance = LearningApiService._();

  final _api = AppApi.instance;

  /// Lấy danh sách các lộ trình học đang active
  Future<List<Map<String, dynamic>>> getPaths() async {
    final response = await _api.dio.get<dynamic>('/learning/paths');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }
    return const [];
  }

  /// Lấy chi tiết lộ trình kèm các Unit và danh sách Lesson tóm tắt
  Future<Map<String, dynamic>> getPathDetail(String pathId) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/learning/paths/$pathId',
    );
    return response.data ?? const <String, dynamic>{};
  }

  /// Lấy chi tiết bài học kèm content_data (danh sách bài tập tương tác)
  Future<Map<String, dynamic>> getLessonDetail(String lessonId) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/learning/lessons/$lessonId',
    );
    return response.data ?? const <String, dynamic>{};
  }

  /// Nộp kết quả làm bài tập để chấm điểm, nhận XP, streak và mở khóa bài tiếp
  Future<Map<String, dynamic>> submitLesson({
    required String lessonId,
    required int score,
    required int timeSpentSeconds,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/learning/lessons/$lessonId/submit',
      data: {
        'score': score,
        'time_spent_seconds': timeSpentSeconds,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }
}
