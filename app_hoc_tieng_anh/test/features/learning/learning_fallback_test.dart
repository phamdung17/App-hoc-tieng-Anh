// test/features/learning/learning_fallback_test.dart
//
// Verification of LearningRepository network resiliency and offline fallback:
// 1. Connection error (network down) -> fallbacks to MockLearningRepository with zero crash.
// 2. Connection timeout -> fallbacks to MockLearningRepository.
// 3. Server 500 error -> fallbacks to MockLearningRepository.
// 4. UUID lesson detail error -> graceful fallback to mock lesson.
// 5. UUID submit error -> local mock completion with is_offline = true.

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/core/network/app_api.dart';
import 'package:app_hoc_tieng_anh/features/learning/data/learning_repository.dart';

class ThrowingHttpClientAdapter implements HttpClientAdapter {
  final DioException Function(RequestOptions options) errorGenerator;

  ThrowingHttpClientAdapter(this.errorGenerator);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw errorGenerator(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  late HttpClientAdapter originalAdapter;
  final repository = LearningRepository.instance;

  setUp(() {
    originalAdapter = AppApi.instance.dio.httpClientAdapter;
  });

  tearDown(() {
    AppApi.instance.dio.httpClientAdapter = originalAdapter;
  });

  group('LearningRepository Network Resilience & Mock Fallback', () {
    test('getUnits falls back to MockLearningRepository on connection error', () async {
      AppApi.instance.dio.httpClientAdapter = ThrowingHttpClientAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Connection refused / host unreachable',
        ),
      );

      final units = await repository.getUnits();
      expect(units, isNotEmpty);
      expect(units.first.title, contains('Chào hỏi'));
      expect(units.first.lessons, isNotEmpty);
    });

    test('getUnits falls back to MockLearningRepository on connection timeout', () async {
      AppApi.instance.dio.httpClientAdapter = ThrowingHttpClientAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timed out after 10000ms',
        ),
      );

      final units = await repository.getUnits();
      expect(units, isNotEmpty);
      expect(units.length, greaterThanOrEqualTo(2));
    });

    test('getUnits falls back to MockLearningRepository on HTTP 500 internal server error', () async {
      AppApi.instance.dio.httpClientAdapter = ThrowingHttpClientAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            statusMessage: 'Internal Server Error',
          ),
        ),
      );

      final units = await repository.getUnits();
      expect(units, isNotEmpty);
      expect(units.first.lessons.first.title, isNotEmpty);
    });

    test('getLessonDetail falls back to Mock on backend failure for UUID lesson', () async {
      const validUuid = '550e8400-e29b-41d4-a716-446655440000';

      AppApi.instance.dio.httpClientAdapter = ThrowingHttpClientAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Backend down',
        ),
      );

      final detail = await repository.getLessonDetail(validUuid);
      expect(detail, isNotNull);
      expect(detail.title, isNotEmpty);
      expect(detail.exercises, isNotEmpty);
    });

    test('submitLesson completes offline and records mock progress on network error for UUID', () async {
      const validUuid = '550e8400-e29b-41d4-a716-446655440000';

      AppApi.instance.dio.httpClientAdapter = ThrowingHttpClientAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Cannot submit to backend',
        ),
      );

      final result = await repository.submitLesson(
        lessonId: validUuid,
        score: 80,
        timeSpentSeconds: 90,
      );

      expect(result['lesson_status'], equals('completed'));
      expect(result['xp_earned'], equals(25));
      expect(result['is_offline'], isTrue);
    });

    test('Mock identifiers load mock data directly without network requests', () async {
      // Set adapter to throw to verify network is not even called for mock id
      AppApi.instance.dio.httpClientAdapter = ThrowingHttpClientAdapter(
        (options) => throw StateError('Network should not be touched for mock identifiers!'),
      );

      final detail = await repository.getLessonDetail('unit1_lesson1');
      expect(detail.id, equals('unit1_lesson1'));
      expect(detail.title, isNotEmpty);
      expect(detail.exercises, isNotEmpty);
    });
  });
}
