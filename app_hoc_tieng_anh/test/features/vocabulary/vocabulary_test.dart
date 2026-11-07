import 'package:flutter_test/flutter_test.dart';
import 'package:app_hoc_tieng_anh/features/vocabulary/data/vocabulary_api_service.dart';
import 'package:app_hoc_tieng_anh/features/vocabulary/domain/vocabulary_word.dart';

void main() {
  group('VocabularyWord Domain Model Tests', () {
    test('fromWordApi parses catalog word correctly', () {
      final json = {
        'id': 'word-uuid-1',
        'lemma': 'apple',
        'ipa': '/ˈæp.əl/',
        'meaning_vi': 'quả táo',
        'pos': 'noun',
        'example_en': 'I eat an apple.',
        'example_vi': 'Tôi ăn một quả táo.',
        'topic': 'food',
        'is_seeded': true,
      };

      final word = VocabularyWord.fromWordApi(json);

      expect(word.id, 'word-uuid-1');
      expect(word.word, 'apple');
      expect(word.ipa, '/ˈæp.əl/');
      expect(word.meaningVi, 'quả táo');
      expect(word.partOfSpeech, 'noun');
      expect(word.topic, 'food');
      expect(word.source, 'Catalog');
    });

    test('fromApi parses scan item correctly', () {
      final json = {
        'id': 'scan-item-uuid-2',
        'label': 'bottle',
        'ipa': '/ˈbɑː.t̬əl/',
        'meaning_vi': 'chai nước',
        'pos': 'noun',
        'example_en': 'A bottle of water.',
        'example_vi': 'Một chai nước.',
        'topic': 'daily',
      };

      final word = VocabularyWord.fromApi(json);

      expect(word.id, 'scan-item-uuid-2');
      expect(word.word, 'bottle');
      expect(word.source, 'AI Scan');
    });

    test('copyWith updates note while preserving fields', () {
      const original = VocabularyWord(
        id: '1',
        word: 'coffee',
        ipa: '/ˈkɑː.fi/',
        meaningVi: 'cà phê',
        partOfSpeech: 'noun',
        exampleEn: 'Drink coffee',
        exampleVi: 'Uống cà phê',
        topic: 'drink',
        source: 'Catalog',
        note: '',
      );

      final updated = original.copyWith(note: 'Nhớ uống buổi sáng');

      expect(updated.note, 'Nhớ uống buổi sáng');
      expect(updated.word, 'coffee');
      expect(updated.source, 'Catalog');
    });

    test('VocabListResult holds pagination metadata properly', () {
      final result = VocabListResult(
        items: [
          VocabularyWord.fromWordApi({
            'id': 'w1',
            'lemma': 'hello',
            'ipa': '/həˈloʊ/',
            'meaning_vi': 'xin chào',
            'pos': 'noun',
            'topic': 'greeting',
            'is_seeded': true,
          }),
        ],
        total: 30,
        page: 1,
        pageSize: 10,
        hasNext: true,
      );

      expect(result.items.length, 1);
      expect(result.total, 30);
      expect(result.page, 1);
      expect(result.hasNext, isTrue);
    });
  });
}

