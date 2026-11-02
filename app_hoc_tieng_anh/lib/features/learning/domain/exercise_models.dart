// Domain models for interactive learning exercises
import 'package:flutter/material.dart';

enum ExerciseType { choice, wordBank, matchPairs, listening, speaking }

abstract class Exercise {
  final String id;
  final String lessonId;
  final ExerciseType type;
  final String prompt;

  const Exercise({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.prompt,
  });
}

class ChoiceOption {
  final String text;
  final IconData? icon;
  final String? subtitle;

  const ChoiceOption({required this.text, this.icon, this.subtitle});
}

class ChoiceExercise extends Exercise {
  final String targetWord;
  final String ipa;
  final List<ChoiceOption> options;
  final int correctOptionIndex;
  final String explanation;

  const ChoiceExercise({
    required super.id,
    required super.lessonId,
    required super.prompt,
    required this.targetWord,
    required this.ipa,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  }) : super(type: ExerciseType.choice);
}

class WordBankExercise extends Exercise {
  final String vietnameseSentence;
  final List<String> correctWords;
  final List<String> availableWords;
  final String explanation;

  const WordBankExercise({
    required super.id,
    required super.lessonId,
    required super.prompt,
    required this.vietnameseSentence,
    required this.correctWords,
    required this.availableWords,
    required this.explanation,
  }) : super(type: ExerciseType.wordBank);
}

class WordPair {
  final String english;
  final String vietnamese;

  const WordPair({required this.english, required this.vietnamese});
}

class MatchPairsExercise extends Exercise {
  final List<WordPair> pairs;
  final String explanation;

  const MatchPairsExercise({
    required super.id,
    required super.lessonId,
    required super.prompt,
    required this.pairs,
    required this.explanation,
  }) : super(type: ExerciseType.matchPairs);
}

class ListeningExercise extends Exercise {
  final String audioText;
  final String answer;
  const ListeningExercise({
    required super.id,
    required super.lessonId,
    required super.prompt,
    required this.audioText,
    required this.answer,
  }) : super(type: ExerciseType.listening);
}

class SpeakingExercise extends Exercise {
  final String phrase;
  const SpeakingExercise({
    required super.id,
    required super.lessonId,
    required super.prompt,
    required this.phrase,
  }) : super(type: ExerciseType.speaking);
}
