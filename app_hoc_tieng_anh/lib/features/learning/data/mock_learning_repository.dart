// Repository providing realistic mock learning data for offline / prototype usage

import '../domain/exercise_models.dart';
import '../domain/lesson_models.dart';

class MockLearningRepository {
  MockLearningRepository._();

  static final MockLearningRepository instance = MockLearningRepository._();

  // Progress state stored in memory during app run
  int userStreak = 5;
  int userXp = 240;
  int dailyGoalXp = 50;
  int todayXpEarned = 25;

  final Set<String> _completedLessonIds = {'unit1_lesson1'};
  String _currentLessonId = 'unit1_lesson2';

  List<LearningUnit> getUnits() {
    return [
      LearningUnit(
        id: 'unit_1',
        number: 1,
        title: 'Chào hỏi & Làm quen',
        description: 'Học cách chào hỏi, giới thiệu bản thân và mẫu câu cơ bản',
        lessons: [
          LessonNode(
            id: 'unit1_lesson1',
            unitId: 'unit_1',
            title: 'Chào hỏi cơ bản',
            description: 'Hello, Good morning, Nice to meet you',
            order: 1,
            xpReward: 15,
            status: _getLessonStatus('unit1_lesson1'),
          ),
          LessonNode(
            id: 'unit1_lesson2',
            unitId: 'unit_1',
            title: 'Giới thiệu bản thân',
            description: 'Tên, tuổi, nghề nghiệp và quốc gia',
            order: 2,
            xpReward: 20,
            status: _getLessonStatus('unit1_lesson2'),
          ),
          LessonNode(
            id: 'unit1_lesson3',
            unitId: 'unit_1',
            title: 'Ôn tập Chào hỏi',
            description: 'Luyện tập tổng hợp các mẫu câu Unit 1',
            order: 3,
            xpReward: 25,
            status: _getLessonStatus('unit1_lesson3'),
          ),
        ],
      ),
      LearningUnit(
        id: 'unit_2',
        number: 2,
        title: 'Đồ ăn & Thức uống',
        description: 'Tên gọi các món ăn, đồ uống quen thuộc và cách gọi món',
        lessons: [
          LessonNode(
            id: 'unit2_lesson1',
            unitId: 'unit_2',
            title: 'Thực phẩm hàng ngày',
            description: 'Bread, milk, water, apple, coffee',
            order: 1,
            xpReward: 20,
            status: _getLessonStatus('unit2_lesson1'),
          ),
          LessonNode(
            id: 'unit2_lesson2',
            unitId: 'unit_2',
            title: 'Đặt món tại quán',
            description: 'Mẫu câu "Can I have...", "I would like..."',
            order: 2,
            xpReward: 20,
            status: _getLessonStatus('unit2_lesson2'),
          ),
        ],
      ),
      LearningUnit(
        id: 'unit_3',
        number: 3,
        title: 'Du lịch & Giao tiếp',
        description: 'Hỏi đường, mua vé và các tình huống giao tiếp đời sống',
        lessons: [
          LessonNode(
            id: 'unit3_lesson1',
            unitId: 'unit_3',
            title: 'Hỏi đường đi',
            description: 'Turn left, turn right, straight ahead',
            order: 1,
            xpReward: 25,
            status: _getLessonStatus('unit3_lesson1'),
          ),
        ],
      ),
    ];
  }

  LessonStatus _getLessonStatus(String lessonId) {
    if (_completedLessonIds.contains(lessonId)) {
      return LessonStatus.completed;
    }
    if (lessonId == _currentLessonId) {
      return LessonStatus.current;
    }
    return LessonStatus.locked;
  }

  void completeLesson(String lessonId, int xpGained) {
    _completedLessonIds.add(lessonId);
    userXp += xpGained;
    todayXpEarned += xpGained;

    // Advance to next lesson
    if (lessonId == 'unit1_lesson1') {
      _currentLessonId = 'unit1_lesson2';
    } else if (lessonId == 'unit1_lesson2') {
      _currentLessonId = 'unit1_lesson3';
    } else if (lessonId == 'unit1_lesson3') {
      _currentLessonId = 'unit2_lesson1';
    } else if (lessonId == 'unit2_lesson1') {
      _currentLessonId = 'unit2_lesson2';
    } else if (lessonId == 'unit2_lesson2') {
      _currentLessonId = 'unit3_lesson1';
    }
  }

  LessonDetail getLessonDetail(String lessonId) {
    if (lessonId == 'unit1_lesson2') {
      return LessonDetail(
        id: lessonId,
        title: 'Giới thiệu bản thân',
        unitTitle: 'Unit 1: Chào hỏi & Làm quen',
        xpReward: 20,
        exercises: [
          const ChoiceExercise(
            id: 'u1_l2_q1',
            lessonId: 'unit1_lesson2',
            prompt: 'Chọn nghĩa đúng của từ:',
            targetWord: 'Student',
            ipa: '/ˈstjuː.dənt/',
            options: [
              ChoiceOption(text: 'Giáo viên', emoji: '👨‍🏫'),
              ChoiceOption(text: 'Học sinh, sinh viên', emoji: '🧑‍🎓'),
              ChoiceOption(text: 'Bác sĩ', emoji: '👨‍⚕️'),
              ChoiceOption(text: 'Kỹ sư', emoji: '👷'),
            ],
            correctOptionIndex: 1,
            explanation: '"Student" có nghĩa là học sinh hoặc sinh viên.',
          ),
          const WordBankExercise(
            id: 'u1_l2_q2',
            lessonId: 'unit1_lesson2',
            prompt: 'Sắp xếp các từ để hoàn thành câu:',
            vietnameseSentence: 'Tôi là một học sinh.',
            correctWords: ['I', 'am', 'a', 'student'],
            availableWords: ['a', 'am', 'teacher', 'I', 'student', 'is', 'very'],
            explanation: 'Cấu trúc: I + am + a/an + danh từ nghề nghiệp.',
          ),
          const MatchPairsExercise(
            id: 'u1_l2_q3',
            lessonId: 'unit1_lesson2',
            prompt: 'Chạm vào các cặp từ tương ứng:',
            pairs: [
              WordPair(english: 'Name', vietnamese: 'Tên'),
              WordPair(english: 'Friend', vietnamese: 'Bạn bè'),
              WordPair(english: 'Country', vietnamese: 'Đất nước'),
              WordPair(english: 'Teacher', vietnamese: 'Giáo viên'),
            ],
            explanation: 'Các danh từ cơ bản khi giới thiệu bản thân.',
          ),
          const WordBankExercise(
            id: 'u1_l2_q4',
            lessonId: 'unit1_lesson2',
            prompt: 'Dịch câu sau sang tiếng Anh:',
            vietnameseSentence: 'Rất vui được gặp bạn.',
            correctWords: ['Nice', 'to', 'meet', 'you'],
            availableWords: ['Nice', 'Good', 'meet', 'to', 'morning', 'you', 'see'],
            explanation: '"Nice to meet you" là lời chào lịch sự khi gặp ai đó lần đầu.',
          ),
        ],
      );
    }

    // Default lesson fallback with exercises
    return LessonDetail(
      id: lessonId,
      title: 'Chào hỏi cơ bản',
      unitTitle: 'Unit 1: Chào hỏi & Làm quen',
      xpReward: 15,
      exercises: [
        const ChoiceExercise(
          id: 'u1_l1_q1',
          lessonId: 'unit1_lesson1',
          prompt: 'Từ nào mang nghĩa là "Xin chào"?',
          targetWord: 'Hello',
          ipa: '/həˈləʊ/',
          options: [
            ChoiceOption(text: 'Hello', emoji: '👋'),
            ChoiceOption(text: 'Goodbye', emoji: '🏃'),
            ChoiceOption(text: 'Thank you', emoji: '🙏'),
            ChoiceOption(text: 'Sorry', emoji: '🙇'),
          ],
          correctOptionIndex: 0,
          explanation: '"Hello" là từ phổ biến nhất dùng để chào hỏi.',
        ),
        const MatchPairsExercise(
          id: 'u1_l1_q2',
          lessonId: 'unit1_lesson1',
          prompt: 'Ghép cặp từ tiếng Anh và tiếng Việt:',
          pairs: [
            WordPair(english: 'Hello', vietnamese: 'Xin chào'),
            WordPair(english: 'Goodbye', vietnamese: 'Tạm biệt'),
            WordPair(english: 'Thanks', vietnamese: 'Cảm ơn'),
            WordPair(english: 'Yes', vietnamese: 'Có / Đúng'),
          ],
          explanation: 'Các từ vựng chào hỏi giao tiếp cơ bản.',
        ),
        const WordBankExercise(
          id: 'u1_l1_q3',
          lessonId: 'unit1_lesson1',
          prompt: 'Ghép các từ thành lời chào buổi sáng:',
          vietnameseSentence: 'Chào buổi sáng!',
          correctWords: ['Good', 'morning'],
          availableWords: ['night', 'Good', 'morning', 'afternoon', 'hello'],
          explanation: '"Good morning" dùng để chào vào buổi sáng.',
        ),
      ],
    );
  }
}
