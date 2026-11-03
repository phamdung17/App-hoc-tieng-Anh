// test/features/learning/learning_api_service_test.dart
//
// Verification of LearningApiService API endpoints and response parsing:
// 1. getPaths() -> returns List<Map<String, dynamic>>
// 2. getPathDetail(pathId) -> returns Map<String, dynamic> with units & lessons
// 3. getLessonDetail(lessonId) -> returns Map<String, dynamic> with content_data
// 4. submitLesson(...) -> sends score/time and returns response payload

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/core/network/app_api.dart';
import 'package:app_hoc_tieng_anh/features/learning/data/learning_api_service.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  late HttpClientAdapter originalAdapter;
  final service = LearningApiService.instance;

  setUp(() {
    originalAdapter = AppApi.instance.dio.httpClientAdapter;
  });

  tearDown(() {
    AppApi.instance.dio.httpClientAdapter = originalAdapter;
  });

  group('LearningApiService Endpoint Tests', () {
    test('getPaths successfully requests /learning/paths and parses list', () async {
      final mockData = [
        {
          'id': 'path-uuid-1',
          'code': 'path_beginner',
          'title': 'Tiếng Anh Giao Tiếp Cơ Bản',
          'level': 'beginner',
          'total_units': 3,
          'total_lessons': 9,
          'completed_lessons': 2,
        },
        {
          'id': 'path-uuid-2',
          'code': 'path_work',
          'title': 'Tiếng Anh Công Sở & Phỏng Vấn',
          'level': 'intermediate',
          'total_units': 2,
          'total_lessons': 6,
          'completed_lessons': 0,
        }
      ];

      AppApi.instance.dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, contains('/learning/paths'));
        expect(options.method, equals('GET'));
        return ResponseBody.fromString(
          jsonEncode(mockData),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final paths = await service.getPaths();
      expect(paths.length, equals(2));
      expect(paths[0]['title'], equals('Tiếng Anh Giao Tiếp Cơ Bản'));
      expect(paths[0]['completed_lessons'], equals(2));
      expect(paths[1]['level'], equals('intermediate'));
    });

    test('getPathDetail successfully requests /learning/paths/{id}', () async {
      const pathId = 'path-uuid-1';
      final mockDetail = {
        'id': pathId,
        'title': 'Tiếng Anh Giao Tiếp Cơ Bản',
        'level': 'beginner',
        'units': [
          {
            'id': 'unit-uuid-1',
            'title': 'Unit 1: Chào hỏi & Làm quen',
            'order_index': 1,
            'lessons': [
              {
                'id': 'lesson-uuid-1',
                'title': 'Chào hỏi cơ bản',
                'status': 'available',
                'xp_reward': 20,
              }
            ]
          }
        ]
      };

      AppApi.instance.dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, contains('/learning/paths/$pathId'));
        expect(options.method, equals('GET'));
        return ResponseBody.fromString(
          jsonEncode(mockDetail),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final detail = await service.getPathDetail(pathId);
      expect(detail['id'], equals(pathId));
      expect(detail['units'], isA<List>());
      final units = detail['units'] as List;
      expect(units.length, equals(1));
      expect(units[0]['title'], contains('Unit 1'));
    });

    test('getLessonDetail successfully requests /learning/lessons/{id}', () async {
      const lessonId = 'lesson-uuid-1';
      final mockLessonDetail = {
        'id': lessonId,
        'title': 'Chào hỏi cơ bản',
        'lesson_type': 'standard',
        'xp_reward': 20,
        'content_data': {
          'exercises': [
            {
              'type': 'choice',
              'prompt': 'Chọn nghĩa của từ Hello:',
              'target_word': 'Hello',
              'options': [{'text': 'Xin chào'}, {'text': 'Tạm biệt'}],
              'correct_option_index': 0,
            }
          ]
        }
      };

      AppApi.instance.dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, contains('/learning/lessons/$lessonId'));
        expect(options.method, equals('GET'));
        return ResponseBody.fromString(
          jsonEncode(mockLessonDetail),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final lesson = await service.getLessonDetail(lessonId);
      expect(lesson['id'], equals(lessonId));
      expect(lesson['title'], equals('Chào hỏi cơ bản'));
      expect(lesson['content_data'], isNotNull);
    });

    test('submitLesson sends correct body and receives submission result', () async {
      const lessonId = 'lesson-uuid-1';
      final mockResponse = {
        'lesson_id': lessonId,
        'passed': true,
        'score': 85,
        'xp_earned': 20,
        'new_total_xp': 220,
        'streak_days': 5,
        'lesson_status': 'completed',
        'unlocked_lessons': ['lesson-uuid-2'],
      };

      AppApi.instance.dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, contains('/learning/lessons/$lessonId/submit'));
        expect(options.method, equals('POST'));

        final body = options.data as Map<String, dynamic>;
        expect(body['score'], equals(85));
        expect(body['time_spent_seconds'], equals(120));

        return ResponseBody.fromString(
          jsonEncode(mockResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final result = await service.submitLesson(
        lessonId: lessonId,
        score: 85,
        timeSpentSeconds: 120,
      );

      expect(result['passed'], isTrue);
      expect(result['xp_earned'], equals(20));
      expect(result['streak_days'], equals(5));
      expect(result['lesson_status'], equals('completed'));
    });
  });
}
