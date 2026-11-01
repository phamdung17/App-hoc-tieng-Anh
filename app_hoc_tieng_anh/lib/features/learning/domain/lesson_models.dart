// Domain models for units, lessons and lesson results

import 'exercise_models.dart';

enum LessonStatus {
  completed,
  current,
  locked,
}

class LessonNode {
  final String id;
  final String unitId;
  final String title;
  final String description;
  final int order;
  final int xpReward;
  final LessonStatus status;
  final int exerciseCount;

  const LessonNode({
    required this.id,
    required this.unitId,
    required this.title,
    required this.description,
    required this.order,
    this.xpReward = 15,
    this.status = LessonStatus.locked,
    this.exerciseCount = 4,
  });

  LessonNode copyWith({
    LessonStatus? status,
  }) {
    return LessonNode(
      id: id,
      unitId: unitId,
      title: title,
      description: description,
      order: order,
      xpReward: xpReward,
      status: status ?? this.status,
      exerciseCount: exerciseCount,
    );
  }
}

class LearningUnit {
  final String id;
  final int number;
  final String title;
  final String description;
  final List<LessonNode> lessons;

  const LearningUnit({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.lessons,
  });
}

class LessonDetail {
  final String id;
  final String title;
  final String unitTitle;
  final int xpReward;
  final List<Exercise> exercises;

  const LessonDetail({
    required this.id,
    required this.title,
    required this.unitTitle,
    required this.xpReward,
    required this.exercises,
  });
}

class LessonResult {
  final String lessonId;
  final String lessonTitle;
  final int xpEarned;
  final int accuracyPercentage;
  final int totalQuestions;
  final int correctCount;
  final int durationSeconds;
  final int streakDays;

  const LessonResult({
    required this.lessonId,
    required this.lessonTitle,
    required this.xpEarned,
    required this.accuracyPercentage,
    required this.totalQuestions,
    required this.correctCount,
    required this.durationSeconds,
    required this.streakDays,
  });
}
