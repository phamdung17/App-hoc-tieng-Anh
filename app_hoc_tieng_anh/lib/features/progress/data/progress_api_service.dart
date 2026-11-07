// lib/features/progress/data/progress_api_service.dart
//
// Service gọi API FastAPI cho phân hệ thống kê tiến độ học tập:
// - GET /progress/summary
// - GET /progress/calendar?days=30

import '../../../../core/network/app_api.dart';
import '../domain/progress_models.dart';

class ProgressApiService {
  ProgressApiService._({AppApi? api}) : _api = api ?? AppApi.instance;
  static final ProgressApiService instance = ProgressApiService._();

  final AppApi _api;

  /// Lấy thông tin tóm tắt tiến trình học tập của user hiện tại
  Future<ProgressSummary> getSummary() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/progress/summary',
    );
    final data = response.data ?? const <String, dynamic>{};
    return ProgressSummary.fromJson(data);
  }

  /// Lấy lịch sử học tập và streak N ngày gần nhất (mặc định 30, tối đa 90)
  Future<CalendarProgress> getCalendar({int days = 30}) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/progress/calendar',
      queryParameters: {'days': days.clamp(1, 90)},
    );
    final data = response.data ?? const <String, dynamic>{};
    return CalendarProgress.fromJson(data);
  }
}

