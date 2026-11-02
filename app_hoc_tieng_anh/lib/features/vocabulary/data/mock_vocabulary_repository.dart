// Mock repository cho kho từ vựng – giữ dữ liệu trong memory khi app chạy

import '../domain/vocabulary_word.dart';
import '../../scan/domain/scan_models.dart';

class MockVocabularyRepository {
  MockVocabularyRepository._();
  static final MockVocabularyRepository instance = MockVocabularyRepository._();

  final List<VocabularyWord> _words = [
    VocabularyWord(
      id: 'vocab_coffee',
      word: 'Coffee Cup',
      ipa: '/ˈkɒf.i kʌp/',
      partOfSpeech: 'noun',
      meaningVi: 'Cốc cà phê',
      exampleEn: 'He is drinking a warm cup of coffee.',
      exampleVi: 'Anh ấy đang uống một tách cà phê ấm.',
      emoji: '☕',
      source: 'AI Scan',
      masteryLevel: MasteryLevel.learning,
      addedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    VocabularyWord(
      id: 'vocab_notebook',
      word: 'Notebook',
      ipa: '/ˈnəʊt.bʊk/',
      partOfSpeech: 'noun',
      meaningVi: 'Quyển vở, sổ tay ghi chép',
      exampleEn: 'I write my daily study notes in this notebook.',
      exampleVi: 'Tôi viết ghi chú học tập hàng ngày vào quyển sổ này.',
      emoji: '📖',
      source: 'AI Scan',
      masteryLevel: MasteryLevel.familiar,
      addedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    VocabularyWord(
      id: 'vocab_student',
      word: 'Student',
      ipa: '/ˈstjuː.dənt/',
      partOfSpeech: 'noun',
      meaningVi: 'Học sinh, sinh viên',
      exampleEn: 'She is a hard-working student.',
      exampleVi: 'Cô ấy là một sinh viên chăm chỉ.',
      emoji: '🧑‍🎓',
      source: 'Bài học',
      masteryLevel: MasteryLevel.mastered,
      addedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    VocabularyWord(
      id: 'vocab_apple',
      word: 'Apple',
      ipa: '/ˈæp.əl/',
      partOfSpeech: 'noun',
      meaningVi: 'Quả táo',
      exampleEn: 'An apple a day keeps the doctor away.',
      exampleVi: 'Ăn một quả táo mỗi ngày giúp bạn luôn khỏe mạnh.',
      emoji: '🍎',
      source: 'Tự thêm',
      masteryLevel: MasteryLevel.newWord,
      addedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    VocabularyWord(
      id: 'vocab_laptop',
      word: 'Laptop',
      ipa: '/ˈlæp.tɒp/',
      partOfSpeech: 'noun',
      meaningVi: 'Máy tính xách tay',
      exampleEn: 'She uses a laptop to learn English online.',
      exampleVi: 'Cô ấy dùng máy tính xách tay để học tiếng Anh trực tuyến.',
      emoji: '💻',
      source: 'AI Scan',
      masteryLevel: MasteryLevel.learning,
      addedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<VocabularyWord> getWords() => List.unmodifiable(_words);

  VocabularyWord? getWordById(String id) {
    try {
      return _words.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isSaved(String id) => _words.any((w) => w.id == id);

  /// Thêm từ từ kết quả AI Scan vào kho từ.
  void addFromScan(DetectedObject obj) {
    if (isSaved(obj.id)) return;

    _words.insert(
      0,
      VocabularyWord(
        id: obj.id,
        word: obj.label,
        ipa: obj.ipa,
        partOfSpeech: obj.partOfSpeech,
        meaningVi: obj.meaningVi,
        exampleEn: obj.exampleEn,
        exampleVi: obj.exampleVi,
        emoji: null,
        source: 'AI Scan',
        masteryLevel: MasteryLevel.newWord,
        addedAt: DateTime.now(),
      ),
    );
  }

  void updateMastery(String id, MasteryLevel level) {
    final index = _words.indexWhere((w) => w.id == id);
    if (index != -1) {
      _words[index] = _words[index].copyWith(masteryLevel: level);
    }
  }

  void updateNote(String id, String? note) {
    final index = _words.indexWhere((w) => w.id == id);
    if (index != -1) {
      _words[index] = _words[index].copyWith(note: note);
    }
  }

  void deleteWord(String id) {
    _words.removeWhere((w) => w.id == id);
  }
}
