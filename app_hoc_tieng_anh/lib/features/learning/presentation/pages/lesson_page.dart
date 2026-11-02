import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../../core/audio/app_sound_effects.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/mock_learning_repository.dart';
import '../../domain/exercise_models.dart';
import '../../domain/lesson_models.dart';
import '../exercises/image_choice_exercise_widget.dart';
import '../exercises/listening_exercise_widget.dart';
import '../exercises/match_pairs_exercise_widget.dart';
import '../exercises/speaking_exercise_widget.dart';
import '../exercises/word_bank_exercise_widget.dart';
import '../widgets/answer_feedback_sheet.dart';
import '../widgets/exit_lesson_dialog.dart';
import '../widgets/lesson_progress_bar.dart';

class LessonPage extends StatefulWidget {
  final String lessonId;

  const LessonPage({super.key, required this.lessonId});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late LessonDetail _lessonDetail;
  late List<Exercise> _exerciseQueue;
  int _totalOriginalCount = 0;

  int _currentIndex = 0;
  int _correctCount = 0;
  int _attemptsCount = 0;
  final DateTime _startTime = DateTime.now();

  // Answer states
  int? _selectedChoiceIndex;
  List<String> _selectedWordBankWords = [];
  bool _matchPairsDone = false;
  String _listeningAnswer = '';
  bool _speakingDone = false;

  bool _isAnswerChecked = false;
  bool _isCurrentCorrect = false;
  String _currentExplanation = '';
  String? _currentCorrectAnswerText;

  @override
  void initState() {
    super.initState();
    _lessonDetail = MockLearningRepository.instance.getLessonDetail(
      widget.lessonId,
    );
    _exerciseQueue = List.from(_lessonDetail.exercises);
    _totalOriginalCount = _exerciseQueue.length;
  }

  void _resetCurrentAnswerState() {
    setState(() {
      _selectedChoiceIndex = null;
      _selectedWordBankWords = [];
      _matchPairsDone = false;
      _listeningAnswer = '';
      _speakingDone = false;
      _isAnswerChecked = false;
      _isCurrentCorrect = false;
      _currentExplanation = '';
      _currentCorrectAnswerText = null;
    });
  }

  bool _canCheckAnswer() {
    if (_isAnswerChecked) return false;
    if (_exerciseQueue.isEmpty) return false;

    final current = _exerciseQueue[_currentIndex];
    switch (current.type) {
      case ExerciseType.choice:
        return _selectedChoiceIndex != null;
      case ExerciseType.wordBank:
        return _selectedWordBankWords.isNotEmpty;
      case ExerciseType.matchPairs:
        return _matchPairsDone;
      case ExerciseType.listening:
        return _listeningAnswer.isNotEmpty;
      case ExerciseType.speaking:
        return _speakingDone;
    }
  }

  void _checkAnswer() {
    final current = _exerciseQueue[_currentIndex];
    _attemptsCount++;

    bool isCorrect = false;
    String explanation = '';
    String? correctAnswerText;

    if (current is ChoiceExercise) {
      isCorrect = _selectedChoiceIndex == current.correctOptionIndex;
      explanation = current.explanation;
      correctAnswerText = current.options[current.correctOptionIndex].text;
    } else if (current is WordBankExercise) {
      final joinedSelected = _selectedWordBankWords.join(' ');
      final joinedTarget = current.correctWords.join(' ');
      isCorrect =
          joinedSelected.trim().toLowerCase() ==
          joinedTarget.trim().toLowerCase();
      explanation = current.explanation;
      correctAnswerText = current.correctWords.join(' ');
    } else if (current is MatchPairsExercise) {
      isCorrect = true;
      explanation = current.explanation;
    } else if (current is ListeningExercise) {
      isCorrect =
          _listeningAnswer.trim().toLowerCase() == current.answer.toLowerCase();
      explanation = 'Câu nghe: ${current.answer}';
      correctAnswerText = current.answer;
    } else if (current is SpeakingExercise) {
      isCorrect = true;
      explanation = 'Bạn đã hoàn thành lượt luyện phát âm.';
    }

    if (isCorrect) {
      _correctCount++;
    }

    setState(() {
      _isAnswerChecked = true;
      _isCurrentCorrect = isCorrect;
      _currentExplanation = explanation;
      _currentCorrectAnswerText = isCorrect ? null : correctAnswerText;
    });
    unawaited(
      AppSoundEffects.instance.play(
        isCorrect ? AppSoundEffect.correct : AppSoundEffect.incorrect,
      ),
    );
  }

  void _onFeedbackContinue() {
    final current = _exerciseQueue[_currentIndex];

    if (!_isCurrentCorrect) {
      // Re-queue the failed exercise to repeat later
      _exerciseQueue.add(current);
    }

    // Move to next
    if (_currentIndex + 1 < _exerciseQueue.length) {
      setState(() {
        _currentIndex++;
      });
      _resetCurrentAnswerState();
    } else {
      // All exercises completed!
      _finishLesson();
    }
  }

  void _finishLesson() {
    unawaited(AppSoundEffects.instance.play(AppSoundEffect.lessonComplete));
    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;
    final accuracy = _attemptsCount > 0
        ? ((_correctCount / _attemptsCount) * 100).round()
        : 100;

    MockLearningRepository.instance.completeLesson(
      widget.lessonId,
      _lessonDetail.xpReward,
    );

    final result = LessonResult(
      lessonId: widget.lessonId,
      lessonTitle: _lessonDetail.title,
      xpEarned: _lessonDetail.xpReward,
      accuracyPercentage: accuracy.clamp(0, 100),
      totalQuestions: _totalOriginalCount,
      correctCount: _correctCount,
      durationSeconds: durationSeconds,
      streakDays: MockLearningRepository.instance.userStreak,
    );

    context.go('/lesson-result', extra: result);
  }

  Future<void> _handleExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => const ExitLessonDialog(),
    );
    if (!mounted || shouldExit != true) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_exerciseQueue.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentExercise = _exerciseQueue[_currentIndex];
    final progress = (_currentIndex) / _exerciseQueue.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar & Close button
              LessonProgressBar(progress: progress, onClose: _handleExit),

              const SizedBox(height: 12),

              // Exercise Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildExerciseView(currentExercise),
                ),
              ),

              // Bottom Action or Feedback Sheet
              if (_isAnswerChecked)
                AnswerFeedbackSheet(
                  isCorrect: _isCurrentCorrect,
                  explanation: _currentExplanation,
                  correctAnswerText: _currentCorrectAnswerText,
                  onContinue: _onFeedbackContinue,
                )
              else
                _buildBottomCheckBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseView(Exercise exercise) {
    if (exercise is ChoiceExercise) {
      return ImageChoiceExerciseWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        selectedIndex: _selectedChoiceIndex,
        onSelectOption: (index) {
          setState(() {
            _selectedChoiceIndex = index;
          });
        },
      );
    } else if (exercise is WordBankExercise) {
      return WordBankExerciseWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        onAnswerChanged: (words) {
          setState(() {
            _selectedWordBankWords = words;
          });
        },
      );
    } else if (exercise is MatchPairsExercise) {
      return MatchPairsExerciseWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        onCompleted: () {
          setState(() {
            _matchPairsDone = true;
          });
          // Auto check on match pairs completion
          _checkAnswer();
        },
      );
    } else if (exercise is ListeningExercise) {
      return ListeningExerciseWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        onAnswerChanged: (value) => setState(() => _listeningAnswer = value),
      );
    } else if (exercise is SpeakingExercise) {
      return SpeakingExerciseWidget(
        key: ValueKey(exercise.id),
        exercise: exercise,
        onDone: () {
          setState(() => _speakingDone = true);
          _checkAnswer();
        },
      );
    }

    return const SizedBox();
  }

  Widget _buildBottomCheckBar() {
    final canCheck = _canCheckAnswer();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: ElevatedButton(
        onPressed: canCheck ? _checkAnswer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.divider,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.textHint,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          elevation: canCheck ? 2 : 0,
        ),
        child: const Text(
          'KIỂM TRA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
