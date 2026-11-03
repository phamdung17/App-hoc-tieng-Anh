// Standalone empirical test runner for parseExercises resilience on malformed inputs

void assertTrue(bool condition, String message) {
  if (!condition) {
    throw Exception('FAILED: $message');
  }
}

void assertEquals(dynamic actual, dynamic expected, String message) {
  if (actual != expected) {
    throw Exception('FAILED: $message - Expected: "$expected", Got: "$actual"');
  }
}

List<Map<String, dynamic>> parseExercises(String lessonId, dynamic contentData) {
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

  final List<Map<String, dynamic>> exercises = [];
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
          final List<Map<String, String>> options = [];

          if (rawOptions is List) {
            for (final opt in rawOptions) {
              if (opt is Map) {
                options.add({
                  'text': opt['text']?.toString() ?? opt['label']?.toString() ?? '',
                  'subtitle': opt['subtitle']?.toString() ?? '',
                });
              } else if (opt is String) {
                options.add({'text': opt, 'subtitle': ''});
              }
            }
          }

          final correctIdx = item['correctOptionIndex'] is num
              ? (item['correctOptionIndex'] as num).toInt()
              : (item['correct_option_index'] is num
                  ? (item['correct_option_index'] as num).toInt()
                  : 0);

          exercises.add({
            'type': 'choice',
            'id': id,
            'lessonId': lessonId,
            'prompt': prompt.isNotEmpty ? prompt : 'Chọn nghĩa đúng của từ:',
            'targetWord': targetWord,
            'ipa': ipa,
            'options': options,
            'correctOptionIndex': correctIdx,
            'explanation': explanation,
          });
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

          exercises.add({
            'type': 'word_bank',
            'id': id,
            'lessonId': lessonId,
            'prompt': prompt.isNotEmpty ? prompt : 'Sắp xếp các từ để hoàn thành câu:',
            'vietnameseSentence': sentence,
            'correctWords': correctWords,
            'availableWords': availableWords,
            'explanation': explanation,
          });
          break;

        case 'match_pairs':
        case 'matchpairs':
        case 'matching':
          final rawPairs = item['pairs'];
          final List<Map<String, String>> pairs = [];

          if (rawPairs is List) {
            for (final p in rawPairs) {
              if (p is Map) {
                pairs.add({
                  'english': p['english']?.toString() ?? p['en']?.toString() ?? '',
                  'vietnamese': p['vietnamese']?.toString() ?? p['vi']?.toString() ?? '',
                });
              }
            }
          }

          exercises.add({
            'type': 'match_pairs',
            'id': id,
            'lessonId': lessonId,
            'prompt': prompt.isNotEmpty ? prompt : 'Chạm vào các cặp từ tương ứng:',
            'pairs': pairs,
            'explanation': explanation,
          });
          break;

        case 'listening':
          final audioText = item['audioText']?.toString() ??
              item['audio_text']?.toString() ??
              item['text']?.toString() ??
              '';
          final answer = item['answer']?.toString() ?? '';

          exercises.add({
            'type': 'listening',
            'id': id,
            'lessonId': lessonId,
            'prompt': prompt.isNotEmpty ? prompt : 'Nghe và điền từ còn thiếu',
            'audioText': audioText,
            'answer': answer,
          });
          break;

        case 'speaking':
          final phrase = item['phrase']?.toString() ??
              item['sentence']?.toString() ??
              '';

          exercises.add({
            'type': 'speaking',
            'id': id,
            'lessonId': lessonId,
            'prompt': prompt.isNotEmpty ? prompt : 'Đọc câu sau thành tiếng',
            'phrase': phrase,
          });
          break;
      }
    } catch (e) {
      // Ignored gracefully
    }
  }

  return exercises;
}

void main() {
  print('=== STARTING EXERCISE PARSER RESILIENCE TESTS ===');

  // Test 1: Null or primitives
  assertEquals(parseExercises('l1', null).length, 0, 'Null input');
  assertEquals(parseExercises('l1', 12345).length, 0, 'Int input');
  assertEquals(parseExercises('l1', 'raw_string').length, 0, 'String input');
  assertEquals(parseExercises('l1', true).length, 0, 'Bool input');
  assertEquals(parseExercises('l1', {}).length, 0, 'Empty Map');
  assertEquals(parseExercises('l1', []).length, 0, 'Empty List');

  // Test 2: Corrupted list items
  final mixedList = [null, 123, 'corrupt', {'type': 'unknown_type_99'}];
  assertEquals(parseExercises('l1', mixedList).length, 0, 'Mixed invalid items');

  // Test 3: Choice with missing/null options
  final corruptChoice = {
    'exercises': [
      {
        'type': 'choice',
        'prompt': null,
        'target_word': null,
        'options': null,
        'correct_option_index': 'invalid_string',
      }
    ]
  };
  final resChoice = parseExercises('l1', corruptChoice);
  assertEquals(resChoice.length, 1, 'Choice fallback');
  assertEquals(resChoice[0]['correctOptionIndex'], 0, 'Choice default correct option index');
  assertEquals(resChoice[0]['prompt'], 'Chọn nghĩa đúng của từ:', 'Choice default prompt');

  // Test 4: Word bank with invalid types
  final corruptWb = {
    'exercises': [
      {
        'type': 'word_bank',
        'sentence': 9999,
        'correct_words': [1, 2, 'three'],
        'available_words': 'not_a_list',
      }
    ]
  };
  final resWb = parseExercises('l1', corruptWb);
  assertEquals(resWb.length, 1, 'WordBank parse');
  assertEquals(resWb[0]['vietnameseSentence'], '9999', 'Sentence converted to string');
  assertEquals((resWb[0]['correctWords'] as List).length, 3, 'Correct words converted');
  assertEquals((resWb[0]['availableWords'] as List).length, 0, 'Available words empty list');

  print('=== ALL EXERCISE PARSER RESILIENCE TESTS PASSED! ===');
}
