import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/features/learning/data/learning_repository.dart';
import 'package:app_hoc_tieng_anh/features/learning/domain/exercise_models.dart';

void main() {
  group('LearningRepository UUID & Fallback Detection Tests', () {
    test('isUuid correctly distinguishes standard UUIDs from mock identifiers', () {
      expect(LearningRepository.isUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      expect(LearningRepository.isUuid('a3c10a1b-3d60-4e55-8d07-2a5b6f3c1d9e'), isTrue);
      expect(LearningRepository.isUuid('unit1_lesson1'), isFalse);
      expect(LearningRepository.isUuid('unit1_lesson2'), isFalse);
      expect(LearningRepository.isUuid(''), isFalse);
      expect(LearningRepository.isUuid('12345'), isFalse);
    });

    test('getLessonDetail rejects mock IDs instead of substituting mock data', () async {
      final repository = LearningRepository.instance;
      await expectLater(
        repository.getLessonDetail('unit1_lesson2'),
        throwsA(isA<FormatException>()),
      );
    });

    test('getUnits reports backend errors instead of returning mock units', () async {
      final repository = LearningRepository.instance;
      await expectLater(repository.getUnits(), throwsA(anything));
    });

    test('submitLesson rejects mock IDs instead of recording fake progress', () async {
      final repository = LearningRepository.instance;
      await expectLater(
        repository.submitLesson(
          lessonId: 'unit1_lesson1',
          score: 90,
          timeSpentSeconds: 45,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LearningRepository ExerciseParser Tests', () {
    test('parses choice exercises correctly', () {
      final rawData = {
        'exercises': [
          {
            'type': 'choice',
            'id': 'ex_1',
            'prompt': 'Chọn nghĩa của từ:',
            'target_word': 'Apple',
            'ipa': '/ˈæp.əl/',
            'options': [
              {'text': 'Quả táo'},
              {'text': 'Quả cam'},
            ],
            'correct_option_index': 0,
            'explanation': 'Apple là quả táo.',
          }
        ]
      };

      final exercises = LearningRepository.parseExercises('lesson_1', rawData);
      expect(exercises.length, 1);
      expect(exercises.first, isA<ChoiceExercise>());
      final choice = exercises.first as ChoiceExercise;
      expect(choice.targetWord, 'Apple');
      expect(choice.options.length, 2);
      expect(choice.correctOptionIndex, 0);
    });

    test('parses word bank exercises correctly', () {
      final rawData = [
        {
          'type': 'word_bank',
          'id': 'ex_2',
          'prompt': 'Sắp xếp câu:',
          'vietnamese_sentence': 'Tôi là học sinh',
          'correct_words': ['I', 'am', 'a', 'student'],
          'available_words': ['I', 'am', 'a', 'student', 'teacher'],
          'explanation': 'I am a student.',
        }
      ];

      final exercises = LearningRepository.parseExercises('lesson_1', rawData);
      expect(exercises.length, 1);
      expect(exercises.first, isA<WordBankExercise>());
      final wb = exercises.first as WordBankExercise;
      expect(wb.vietnameseSentence, 'Tôi là học sinh');
      expect(wb.correctWords, ['I', 'am', 'a', 'student']);
      expect(wb.availableWords.length, 5);
    });

    test('parses match pairs exercises correctly', () {
      final rawData = {
        'exercises': [
          {
            'type': 'match_pairs',
            'id': 'ex_3',
            'prompt': 'Ghép cặp:',
            'pairs': [
              {'english': 'Cat', 'vietnamese': 'Con mèo'},
              {'english': 'Dog', 'vietnamese': 'Con chó'},
            ],
            'explanation': 'Từ vựng động vật.',
          }
        ]
      };

      final exercises = LearningRepository.parseExercises('lesson_1', rawData);
      expect(exercises.length, 1);
      expect(exercises.first, isA<MatchPairsExercise>());
      final mp = exercises.first as MatchPairsExercise;
      expect(mp.pairs.length, 2);
      expect(mp.pairs.first.english, 'Cat');
      expect(mp.pairs.first.vietnamese, 'Con mèo');
    });

    test('parses listening and speaking exercises correctly', () {
      final rawData = {
        'exercises': [
          {
            'type': 'listening',
            'id': 'ex_listen',
            'prompt': 'Nghe từ:',
            'audio_text': 'Hello world',
            'answer': 'Hello',
          },
          {
            'type': 'speaking',
            'id': 'ex_speak',
            'prompt': 'Nói câu sau:',
            'phrase': 'Good morning',
          }
        ]
      };

      final exercises = LearningRepository.parseExercises('lesson_1', rawData);
      expect(exercises.length, 2);
      expect(exercises[0], isA<ListeningExercise>());
      expect((exercises[0] as ListeningExercise).audioText, 'Hello world');
      expect(exercises[1], isA<SpeakingExercise>());
      expect((exercises[1] as SpeakingExercise).phrase, 'Good morning');
    });

    test('handles empty or invalid content data without throwing', () {
      expect(LearningRepository.parseExercises('lesson_1', null), isEmpty);
      expect(LearningRepository.parseExercises('lesson_1', {}), isEmpty);
      expect(LearningRepository.parseExercises('lesson_1', 'invalid string'), isEmpty);
      expect(LearningRepository.parseExercises('lesson_1', [123, null, 'abc']), isEmpty);
    });
  });
}
