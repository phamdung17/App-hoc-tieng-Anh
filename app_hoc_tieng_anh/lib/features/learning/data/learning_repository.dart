// lib/features/learning/data/learning_repository.dart
//
// Repository điều phối dữ liệu học tập (Facade / Offline-First Fallback):
// - Ưu tiên gọi backend FastAPI qua LearningApiService khi có mạng và dữ liệu hợp lệ.
// - Tự động chuyển đổi mượt mà sang MockLearningRepository khi offline, backend lỗi
//   (DioException, 404, 500, timeout), hoặc backend chưa có seed data.
// - Đảm bảo zero crash và tính liên tục cho trải nghiệm người dùng.

import 'dart:developer' as developer;

import '../domain/exercise_models.dart';
import '../domain/lesson_models.dart';
import 'learning_api_service.dart';
import 'mock_learning_repository.dart';

class LearningRepository {
  LearningRepository._({
    LearningApiService? apiService,
    MockLearningRepository? mockRepository,
  })  : _apiService = apiService ?? LearningApiService.instance,
        _mockRepository = mockRepository ?? MockLearningRepository.instance;

  static final LearningRepository instance = LearningRepository._();

  final LearningApiService _apiService;
  final MockLearningRepository _mockRepository;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Kiểm tra chuỗi có đúng định dạng UUID hay không
  static bool isUuid(String id) => _uuidRegex.hasMatch(id.trim());

  int get userStreak => _mockRepository.userStreak;
  set userStreak(int value) => _mockRepository.userStreak = value;

  int get userXp => _mockRepository.userXp;
  set userXp(int value) => _mockRepository.userXp = value;

  int get dailyGoalXp => _mockRepository.dailyGoalXp;
  int get todayXpEarned => _mockRepository.todayXpEarned;

  /// Lấy danh sách Unit cùng các bài học kèm trạng thái tiến độ
  Future<List<LearningUnit>> getUnits() async {
    try {
      final paths = await _apiService.getPaths();
      if (paths.isEmpty) {
        developer.log(
          'LearningRepository: Backend returned empty paths, using mock fallback',
          name: 'LearningRepository',
        );
        return _mockRepository.getUnits();
      }

      final activePath = paths.first;
      final pathId = activePath['id']?.toString();
      if (pathId == null || pathId.isEmpty) {
        return _mockRepository.getUnits();
      }

      final detail = await _apiService.getPathDetail(pathId);
      final rawUnits = detail['units'];
      if (rawUnits is! List || rawUnits.isEmpty) {
        developer.log(
          'LearningRepository: Path detail has no units, using mock fallback',
          name: 'LearningRepository',
        );
        return _mockRepository.getUnits();
      }

      final List<LearningUnit> units = [];
      for (var uIndex = 0; uIndex < rawUnits.length; uIndex++) {
        final u = rawUnits[uIndex];
        if (u is! Map<String, dynamic>) continue;

        final rawLessons = u['lessons'];
        final List<LessonNode> lessons = [];
        final unitId = u['id']?.toString() ?? 'unit_${uIndex + 1}';

        if (rawLessons is List) {
          for (var lIndex = 0; lIndex < rawLessons.length; lIndex++) {
            final l = rawLessons[lIndex];
            if (l is! Map<String, dynamic>) continue;

            final statusStr = (l['status']?.toString() ?? 'locked').toLowerCase();
            LessonStatus status;
            if (statusStr == 'completed') {
              status = LessonStatus.completed;
            } else if (statusStr == 'available') {
              status = LessonStatus.current;
            } else {
              status = LessonStatus.locked;
            }

            final order = l['order_index'] is num
                ? (l['order_index'] as num).toInt() + 1
                : lIndex + 1;
            final xpReward = l['xp_reward'] is num
                ? (l['xp_reward'] as num).toInt()
                : 15;

            lessons.add(
              LessonNode(
                id: l['id']?.toString() ?? 'lesson_${uIndex + 1}_${lIndex + 1}',
                unitId: unitId,
                title: l['title']?.toString() ?? 'Bài học $order',
                description: l['lesson_type']?.toString() ?? 'Bài tập tương tác',
                order: order,
                xpReward: xpReward,
                status: status,
                exerciseCount: 4,
              ),
            );
          }
        }

        final unitNumber = u['order_index'] is num
            ? (u['order_index'] as num).toInt() + 1
            : uIndex + 1;

        units.add(
          LearningUnit(
            id: unitId,
            number: unitNumber,
            title: u['title']?.toString() ?? 'Unit $unitNumber',
            description: u['description']?.toString() ?? '',
            lessons: lessons,
          ),
        );
      }

      if (units.isNotEmpty) {
        return units;
      }
    } catch (e, stack) {
      developer.log(
        'LearningRepository: Failed to load units from backend: $e. Using mock fallback.',
        name: 'LearningRepository',
        error: e,
        stackTrace: stack,
      );
    }

    return _mockRepository.getUnits();
  }

  /// Lấy chi tiết bài học kèm danh sách bài tập tương tác
  Future<LessonDetail> getLessonDetail(String lessonId) async {
    // Nếu ID là mock identifier (không phải UUID) -> nạp mock trực tiếp
    if (!isUuid(lessonId)) {
      developer.log(
        'LearningRepository: Non-UUID lesson id "$lessonId" detected, loading mock directly',
        name: 'LearningRepository',
      );
      return _mockRepository.getLessonDetail(lessonId);
    }

    try {
      final data = await _apiService.getLessonDetail(lessonId);
      if (data.isNotEmpty) {
        final exercises = parseExercises(lessonId, data['content_data']);
        if (exercises.isNotEmpty) {
          final xpReward = data['xp_reward'] is num
              ? (data['xp_reward'] as num).toInt()
              : 20;

          return LessonDetail(
            id: lessonId,
            title: data['title']?.toString() ?? 'Bài học',
            unitTitle: 'Lộ trình LingoUp',
            xpReward: xpReward,
            exercises: exercises,
          );
        }
      }
    } catch (e, stack) {
      developer.log(
        'LearningRepository: Failed to fetch lesson detail for $lessonId: $e',
        name: 'LearningRepository',
        error: e,
        stackTrace: stack,
      );
    }

    // Graceful fallback nếu backend gặp lỗi hoặc exercises rỗng
    return _mockRepository.getLessonDetail(lessonId);
  }

  /// Nộp bài học: Gửi lên Backend để cập nhật streak & activity, fallback an toàn khi offline
  Future<Map<String, dynamic>> submitLesson({
    required String lessonId,
    required int score,
    required int timeSpentSeconds,
    required int xpReward,
  }) async {
    if (!isUuid(lessonId)) {
      _mockRepository.completeLesson(lessonId, xpReward);
      return {
        'score': score,
        'xp_earned': xpReward,
        'streak_days': _mockRepository.userStreak,
        'lesson_status': 'completed',
        'is_offline': true,
      };
    }

    try {
      final response = await _apiService.submitLesson(
        lessonId: lessonId,
        score: score,
        timeSpentSeconds: timeSpentSeconds,
      );

      final xpEarned = response['xp_earned'] is num
          ? (response['xp_earned'] as num).toInt()
          : xpReward;
      final streakDays = response['streak_days'] is num
          ? (response['streak_days'] as num).toInt()
          : _mockRepository.userStreak;
      final newTotalXp = response['new_total_xp'] is num
          ? (response['new_total_xp'] as num).toInt()
          : null;

      if (newTotalXp != null) {
        _mockRepository.userXp = newTotalXp;
      }
      _mockRepository.userStreak = streakDays;
      _mockRepository.completeLesson(lessonId, xpEarned);

      return {
        ...response,
        'xp_earned': xpEarned,
        'streak_days': streakDays,
        'is_offline': false,
      };
    } catch (e, stack) {
      developer.log(
        'LearningRepository: Failed to submit lesson $lessonId to backend: $e. Recording locally.',
        name: 'LearningRepository',
        error: e,
        stackTrace: stack,
      );

      _mockRepository.completeLesson(lessonId, xpReward);
      return {
        'score': score,
        'xp_earned': xpReward,
        'streak_days': _mockRepository.userStreak,
        'lesson_status': 'completed',
        'is_offline': true,
      };
    }
  }

  /// Phân giải danh sách bài tập từ JSONB content_data đa dạng
  static List<Exercise> parseExercises(String lessonId, dynamic contentData) {
    if (contentData == null) return const [];

    List<dynamic> rawList = const [];
    if (contentData is Map) {
      final ex = contentData['exercises'] ?? contentData['data'] ?? contentData['items'];
      if (ex is List) {
        rawList = ex;
      }
    } else if (contentData is List) {
      rawList = contentData;
    }

    final List<Exercise> exercises = [];
    for (var i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      if (item is! Map) continue;

      final type = (item['type']?.toString() ?? 'choice').toLowerCase();
      final id = item['id']?.toString() ?? '${lessonId}_ex_$i';
      final prompt = item['prompt']?.toString() ?? '';
      final explanation = item['explanation']?.toString() ?? '';

      try {
        switch (type) {
          case 'choice':
          case 'multiple_choice':
          case 'image_choice':
            final targetWord = item['targetWord']?.toString() ??
                item['target_word']?.toString() ??
                item['word']?.toString() ??
                '';
            final ipa = item['ipa']?.toString() ?? '';
            final rawOptions = item['options'];
            final List<ChoiceOption> options = [];

            if (rawOptions is List) {
              for (final opt in rawOptions) {
                if (opt is Map) {
                  options.add(
                    ChoiceOption(
                      text: opt['text']?.toString() ??
                          opt['label']?.toString() ??
                          '',
                      subtitle: opt['subtitle']?.toString(),
                    ),
                  );
                } else if (opt is String) {
                  options.add(ChoiceOption(text: opt));
                }
              }
            }

            final correctIdx = item['correctOptionIndex'] is num
                ? (item['correctOptionIndex'] as num).toInt()
                : (item['correct_option_index'] is num
                    ? (item['correct_option_index'] as num).toInt()
                    : 0);

            exercises.add(
              ChoiceExercise(
                id: id,
                lessonId: lessonId,
                prompt: prompt.isNotEmpty ? prompt : 'Chọn nghĩa đúng của từ:',
                targetWord: targetWord,
                ipa: ipa,
                options: options,
                correctOptionIndex: correctIdx,
                explanation: explanation,
              ),
            );
            break;

          case 'word_bank':
          case 'wordbank':
          case 'sentence_builder':
            final sentence = item['vietnameseSentence']?.toString() ??
                item['vietnamese_sentence']?.toString() ??
                item['sentence']?.toString() ??
                '';

            final rawCorrect = item['correctWords'] ?? item['correct_words'];
            final List<String> correctWords = rawCorrect is List
                ? rawCorrect.map((e) => e.toString()).toList()
                : [];

            final rawAvailable = item['availableWords'] ?? item['available_words'];
            final List<String> availableWords = rawAvailable is List
                ? rawAvailable.map((e) => e.toString()).toList()
                : [];

            exercises.add(
              WordBankExercise(
                id: id,
                lessonId: lessonId,
                prompt: prompt.isNotEmpty
                    ? prompt
                    : 'Sắp xếp các từ để hoàn thành câu:',
                vietnameseSentence: sentence,
                correctWords: correctWords,
                availableWords: availableWords,
                explanation: explanation,
              ),
            );
            break;

          case 'match_pairs':
          case 'matchpairs':
          case 'matching':
            final rawPairs = item['pairs'];
            final List<WordPair> pairs = [];

            if (rawPairs is List) {
              for (final p in rawPairs) {
                if (p is Map) {
                  pairs.add(
                    WordPair(
                      english: p['english']?.toString() ??
                          p['en']?.toString() ??
                          '',
                      vietnamese: p['vietnamese']?.toString() ??
                          p['vi']?.toString() ??
                          '',
                    ),
                  );
                }
              }
            }

            exercises.add(
              MatchPairsExercise(
                id: id,
                lessonId: lessonId,
                prompt: prompt.isNotEmpty
                    ? prompt
                    : 'Chạm vào các cặp từ tương ứng:',
                pairs: pairs,
                explanation: explanation,
              ),
            );
            break;

          case 'listening':
            final audioText = item['audioText']?.toString() ??
                item['audio_text']?.toString() ??
                item['text']?.toString() ??
                '';
            final answer = item['answer']?.toString() ?? '';

            exercises.add(
              ListeningExercise(
                id: id,
                lessonId: lessonId,
                prompt: prompt.isNotEmpty ? prompt : 'Nghe và điền từ còn thiếu',
                audioText: audioText,
                answer: answer,
              ),
            );
            break;

          case 'speaking':
            final phrase = item['phrase']?.toString() ??
                item['sentence']?.toString() ??
                '';

            exercises.add(
              SpeakingExercise(
                id: id,
                lessonId: lessonId,
                prompt: prompt.isNotEmpty ? prompt : 'Đọc câu sau thành tiếng',
                phrase: phrase,
              ),
            );
            break;
        }
      } catch (e) {
        developer.log(
          'LearningRepository: Failed to parse exercise at index $i: $e',
          name: 'LearningRepository',
        );
      }
    }

    return exercises;
  }
}
