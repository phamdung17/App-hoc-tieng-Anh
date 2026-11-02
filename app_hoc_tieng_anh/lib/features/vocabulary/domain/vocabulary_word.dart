// Domain model cho một từ vựng trong kho từ cá nhân

import 'package:flutter/material.dart';

/// Mức độ ghi nhớ của người dùng với một từ.
enum MasteryLevel {
  /// Từ mới thêm, chưa học lần nào
  newWord('Mới', 0),

  /// Đang trong quá trình học / ôn
  learning('Đang học', 1),

  /// Đã quen, thỉnh thoảng cần ôn lại
  familiar('Quen thuộc', 2),

  /// Đã thuộc, ít khi quên
  mastered('Đã thuộc', 3);

  final String label;
  final int order;

  const MasteryLevel(this.label, this.order);

  /// Màu đại diện cho mỗi mức.
  Color get color {
    switch (this) {
      case MasteryLevel.newWord:
        return const Color(0xFF99A39F);
      case MasteryLevel.learning:
        return const Color(0xFF4285F4);
      case MasteryLevel.familiar:
        return const Color(0xFFE0922E);
      case MasteryLevel.mastered:
        return const Color(0xFF16866F);
    }
  }
}

class VocabularyWord {
  final String id;
  final String word;
  final String ipa;
  final String partOfSpeech;
  final String meaningVi;
  final String exampleEn;
  final String exampleVi;
  final String? emoji;
  final String source; // 'AI Scan', 'Bài học', 'Tự thêm'
  final MasteryLevel masteryLevel;
  final String? note;
  final DateTime addedAt;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.ipa,
    required this.partOfSpeech,
    required this.meaningVi,
    required this.exampleEn,
    required this.exampleVi,
    this.emoji,
    this.source = 'Tự thêm',
    this.masteryLevel = MasteryLevel.newWord,
    this.note,
    required this.addedAt,
  });

  VocabularyWord copyWith({
    MasteryLevel? masteryLevel,
    String? note,
  }) {
    return VocabularyWord(
      id: id,
      word: word,
      ipa: ipa,
      partOfSpeech: partOfSpeech,
      meaningVi: meaningVi,
      exampleEn: exampleEn,
      exampleVi: exampleVi,
      emoji: emoji,
      source: source,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      note: note ?? this.note,
      addedAt: addedAt,
    );
  }
}
