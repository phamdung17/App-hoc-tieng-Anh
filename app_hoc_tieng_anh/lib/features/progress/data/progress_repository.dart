import '../domain/progress_models.dart';
import 'progress_api_service.dart';

class ProgressRepository {
  ProgressRepository._({ProgressApiService? apiService})
      : _apiService = apiService ?? ProgressApiService.instance;

  static final ProgressRepository instance = ProgressRepository._();

  final ProgressApiService _apiService;

  Future<ProgressSummary> getSummary() => _apiService.getSummary();

  Future<CalendarProgress> getCalendar({int days = 30}) =>
      _apiService.getCalendar(days: days);
}
