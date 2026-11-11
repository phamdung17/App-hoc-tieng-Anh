// test/features/learning/learning_repository_edge_cases_challenge_test.dart
//
// Empirical Challenger: Stress-testing LearningRepository fallback and error handling.
// Edge cases tested:
// - DioException: connection timeout
// - DioException: receive timeout
// - DioException: send timeout
// - DioException: HTTP 404 Bad Response
// - DioException: HTTP 500 Bad Response
// - DioException: SocketException / Connection Error
// - Malformed JSON responses: String, int, empty Map, missing keys, corrupt exercise structures
// - Verification that LearningRepository NEVER throws unhandled exceptions and safely falls back.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/core/network/app_api.dart';
import 'package:app_hoc_tieng_anh/features/learning/data/learning_repository.dart';

class ConfigurableMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) responseProvider;

  ConfigurableMockAdapter(this.responseProvider);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return responseProvider(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late HttpClientAdapter originalAdapter;
  final repository = LearningRepository.instance;
  const sampleUuid = 'a0000000-0000-0000-0000-000000000001';

  setUp(() {
    originalAdapter = AppApi.instance.dio.httpClientAdapter;
  });

  tearDown(() {
    AppApi.instance.dio.httpClientAdapter = originalAdapter;
  });

  group('LearningRepository Fallback on Dio Network Failures', () {
    test('Fallback on Connection Timeout', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out after 15000ms',
        );
      });

      // 1. getUnits must not throw and return mock units
      final units = await repository.getUnits();
      expect(units, isNotEmpty);
      expect(units.first.lessons, isNotEmpty);

      // 2. getLessonDetail must not throw and return fallback lesson
      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);
      expect(lesson.exercises, isNotEmpty);

      // 3. submitLesson must not throw and complete offline
      final submitResult = await repository.submitLesson(
        lessonId: sampleUuid,
        score: 100,
        timeSpentSeconds: 60,
      );
      expect(submitResult['is_offline'], isTrue);
      expect(submitResult['lesson_status'], equals('completed'));
    });

    test('Fallback on Receive Timeout', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timeout after 30000ms',
        );
      });

      final units = await repository.getUnits();
      expect(units, isNotEmpty);

      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);

      final submitResult = await repository.submitLesson(
        lessonId: sampleUuid,
        score: 90,
        timeSpentSeconds: 45,
      );
      expect(submitResult['is_offline'], isTrue);
    });

    test('Fallback on Send Timeout', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.sendTimeout,
          message: 'Send timeout after 30000ms',
        );
      });

      final units = await repository.getUnits();
      expect(units, isNotEmpty);

      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);

      final submitResult = await repository.submitLesson(
        lessonId: sampleUuid,
        score: 85,
        timeSpentSeconds: 50,
      );
      expect(submitResult['is_offline'], isTrue);
    });

    test('Fallback on HTTP 404 Not Found', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            statusMessage: 'Not Found',
            data: {'detail': 'Path or lesson not found in database'},
          ),
        );
      });

      final units = await repository.getUnits();
      expect(units, isNotEmpty);

      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);

      final submitResult = await repository.submitLesson(
        lessonId: sampleUuid,
        score: 75,
        timeSpentSeconds: 30,
      );
      expect(submitResult['is_offline'], isTrue);
    });

    test('Fallback on HTTP 500 Internal Server Error', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            statusMessage: 'Internal Server Error',
            data: {'detail': 'Database connection pool exhausted'},
          ),
        );
      });

      final units = await repository.getUnits();
      expect(units, isNotEmpty);

      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);

      final submitResult = await repository.submitLesson(
        lessonId: sampleUuid,
        score: 95,
        timeSpentSeconds: 120,
      );
      expect(submitResult['is_offline'], isTrue);
    });

    test('Fallback on SocketException (DNS failure or no internet)', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const SocketException('Failed host lookup: api.lingoup.com'),
        );
      });

      final units = await repository.getUnits();
      expect(units, isNotEmpty);

      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);

      final submitResult = await repository.submitLesson(
        lessonId: sampleUuid,
        score: 80,
        timeSpentSeconds: 70,
      );
      expect(submitResult['is_offline'], isTrue);
    });
  });

  group('LearningRepository Resilience on Malformed Backend JSON', () {
    test('Handles String HTML 502 Bad Gateway response', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        return ResponseBody.fromString(
          '<html><body>502 Bad Gateway</body></html>',
          200, // Even if HTTP 200 with HTML body
          headers: {
            Headers.contentTypeHeader: [Headers.textPlainContentType],
          },
        );
      });

      final units = await repository.getUnits();
      expect(units, isNotEmpty);

      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);
      expect(lesson.exercises, isNotEmpty);
    });

    test('Handles empty arrays and missing fields in getUnits', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        if (options.path.contains('/learning/paths/')) {
          // Path detail with units empty
          return ResponseBody.fromString(
            jsonEncode({'id': 'path-1', 'title': 'Test Path', 'units': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        } else {
          // Paths list with 1 path
          return ResponseBody.fromString(
            jsonEncode([{'id': 'path-1', 'title': 'Test Path'}]),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
      });

      final units = await repository.getUnits();
      expect(units, isNotEmpty);
      expect(units.first.title, contains('Chào hỏi'));
    });

    test('Handles corrupt unit & lesson objects with invalid types', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        if (options.path.contains('/learning/paths/')) {
          return ResponseBody.fromString(
            jsonEncode({
              'id': 'path-1',
              'units': [
                null,
                'not a unit',
                123,
                {
                  'id': 'u_valid',
                  'title': 'Corrupted Unit',
                  'order_index': 'not_an_int',
                  'lessons': [
                    null,
                    'string_lesson',
                    {
                      'id': 'l_valid',
                      'title': null,
                      'status': 'UNKNOWN_STATUS_XYZ',
                      'order_index': 'invalid',
                      'xp_reward': 'string_xp',
                    }
                  ]
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        } else {
          return ResponseBody.fromString(
            jsonEncode([{'id': 'path-1'}]),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
      });

      // Must safely parse valid elements or fallback without throwing CastError
      final units = await repository.getUnits();
      expect(units, isNotEmpty);
      expect(units.first.lessons, isNotEmpty);
    });

    test('Handles corrupt content_data in getLessonDetail', () async {
      AppApi.instance.dio.httpClientAdapter = ConfigurableMockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'id': sampleUuid,
            'title': 'Test Corrupt Content',
            'xp_reward': 'twenty', // string instead of int
            'content_data': {
              'exercises': [
                null,
                12345,
                'a string',
                {
                  'type': 'non_existent_type_99',
                  'data': {'foo': 'bar'},
                },
                {
                  'type': 'choice',
                  'prompt': null,
                  'options': [null, 123, {'broken': 'yes'}],
                  'correct_option_index': 'zero',
                }
              ]
            }
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      // Should safely extract what it can or fall back without crashing
      final lesson = await repository.getLessonDetail(sampleUuid);
      expect(lesson, isNotNull);
      expect(lesson.exercises, isNotEmpty);
    });

    test('parseExercises handles null, primitives, and malformed structures without throwing', () {
      expect(LearningRepository.parseExercises('id', null), isEmpty);
      expect(LearningRepository.parseExercises('id', 12345), isEmpty);
      expect(LearningRepository.parseExercises('id', 'not json'), isEmpty);
      expect(LearningRepository.parseExercises('id', true), isEmpty);
      expect(LearningRepository.parseExercises('id', {}), isEmpty);
      expect(LearningRepository.parseExercises('id', {'exercises': null}), isEmpty);
      expect(LearningRepository.parseExercises('id', {'exercises': 'not a list'}), isEmpty);
      expect(LearningRepository.parseExercises('id', [null, 'str', 123, []]), isEmpty);
    });
  });
}
