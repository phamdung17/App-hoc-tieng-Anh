import '../domain/vocabulary_word.dart';

/// Temporary in-memory source until the vocabulary API is implemented.
class MockVocabularyRepository {
  MockVocabularyRepository._();

  static final instance = MockVocabularyRepository._();

  final List<VocabularyWord> _words = [
    const VocabularyWord(
      id: 'coffee-cup',
      word: 'coffee cup',
      ipa: '/ˈkɒf.i kʌp/',
      meaningVi: 'Cốc cà phê',
      partOfSpeech: 'noun',
      exampleEn: 'She is holding a coffee cup.',
      exampleVi: 'Cô ấy đang cầm một chiếc cốc cà phê.',
      topic: 'Đồ vật',
      source: 'AI Scan',
    ),
    const VocabularyWord(
      id: 'notebook',
      word: 'notebook',
      ipa: '/ˈnəʊt.bʊk/',
      meaningVi: 'Quyển sổ tay',
      partOfSpeech: 'noun',
      exampleEn: 'I write new words in my notebook.',
      exampleVi: 'Tôi viết từ mới vào sổ tay.',
      topic: 'Học tập',
      source: 'AI Scan',
    ),
    const VocabularyWord(
      id: 'student',
      word: 'student',
      ipa: '/ˈstjuː.dənt/',
      meaningVi: 'Học sinh, sinh viên',
      partOfSpeech: 'noun',
      exampleEn: 'The student is learning English.',
      exampleVi: 'Bạn học sinh đang học tiếng Anh.',
      topic: 'Con người',
      source: 'Bài học',
    ),
    const VocabularyWord(
      id: 'apple',
      word: 'apple',
      ipa: '/ˈæp.əl/',
      meaningVi: 'Quả táo',
      partOfSpeech: 'noun',
      exampleEn: 'An apple a day is a healthy snack.',
      exampleVi: 'Một quả táo mỗi ngày là món ăn nhẹ lành mạnh.',
      topic: 'Đồ ăn',
      source: 'Từ mới',
    ),
    const VocabularyWord(
      id: 'laptop',
      word: 'laptop',
      ipa: '/ˈlæp.tɒp/',
      meaningVi: 'Máy tính xách tay',
      partOfSpeech: 'noun',
      exampleEn: 'My laptop is on the desk.',
      exampleVi: 'Máy tính xách tay của tôi ở trên bàn.',
      topic: 'Công nghệ',
      source: 'AI Scan',
    ),
  ];

  List<VocabularyWord> getAll() => List.unmodifiable(_words);

  VocabularyWord? getById(String id) {
    for (final word in _words) {
      if (word.id == id) return word;
    }
    return null;
  }

  void updateNote(String id, String note) {
    final index = _words.indexWhere((word) => word.id == id);
    if (index == -1) return;
    _words[index] = _words[index].copyWith(note: note.trim());
  }

  void delete(String id) => _words.removeWhere((word) => word.id == id);
}
