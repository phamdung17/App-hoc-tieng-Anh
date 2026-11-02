import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_models.dart';

class MatchPairsExerciseWidget extends StatefulWidget {
  final MatchPairsExercise exercise;
  final VoidCallback onCompleted;

  const MatchPairsExerciseWidget({
    super.key,
    required this.exercise,
    required this.onCompleted,
  });

  @override
  State<MatchPairsExerciseWidget> createState() =>
      _MatchPairsExerciseWidgetState();
}

class _MatchPairsExerciseWidgetState extends State<MatchPairsExerciseWidget> {
  late List<String> _shuffledEnglish;
  late List<String> _shuffledVietnamese;

  String? _selectedEn;
  String? _selectedVi;
  String? _wrongEn;
  String? _wrongVi;

  final Set<String> _matchedPairs = {}; // Stores matched english keys

  @override
  void initState() {
    super.initState();
    _initPairs();
  }

  @override
  void didUpdateWidget(covariant MatchPairsExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _initPairs();
    }
  }

  void _initPairs() {
    _shuffledEnglish = widget.exercise.pairs.map((p) => p.english).toList()
      ..shuffle(Random());
    _shuffledVietnamese =
        widget.exercise.pairs.map((p) => p.vietnamese).toList()
          ..shuffle(Random());
    _matchedPairs.clear();
    _selectedEn = null;
    _selectedVi = null;
    _wrongEn = null;
    _wrongVi = null;
  }

  void _selectEnglish(String en) {
    if (_matchedPairs.contains(en)) return;

    setState(() {
      _selectedEn = en;
      _wrongEn = null;
      _wrongVi = null;
    });

    _checkMatch();
  }

  void _selectVietnamese(String vi) {
    // Check if vi is already part of matched pair
    final matchedPair = widget.exercise.pairs.any(
      (p) => _matchedPairs.contains(p.english) && p.vietnamese == vi,
    );
    if (matchedPair) return;

    setState(() {
      _selectedVi = vi;
      _wrongEn = null;
      _wrongVi = null;
    });

    _checkMatch();
  }

  void _checkMatch() {
    if (_selectedEn == null || _selectedVi == null) return;

    final en = _selectedEn!;
    final vi = _selectedVi!;

    final isCorrect = widget.exercise.pairs.any(
      (p) => p.english == en && p.vietnamese == vi,
    );

    if (isCorrect) {
      setState(() {
        _matchedPairs.add(en);
        _selectedEn = null;
        _selectedVi = null;
      });

      if (_matchedPairs.length == widget.exercise.pairs.length) {
        widget.onCompleted();
      }
    } else {
      setState(() {
        _wrongEn = en;
        _wrongVi = vi;
        _selectedEn = null;
        _selectedVi = null;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _wrongEn = null;
            _wrongVi = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt
        Text(
          widget.exercise.prompt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // 2 Columns: Left English, Right Vietnamese
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // English Column
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _shuffledEnglish.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _shuffledEnglish[index];
                    final isMatched = _matchedPairs.contains(item);
                    final isSelected = _selectedEn == item;
                    final isWrong = _wrongEn == item;

                    return _PairCard(
                      text: item,
                      isMatched: isMatched,
                      isSelected: isSelected,
                      isWrong: isWrong,
                      onTap: () => _selectEnglish(item),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Vietnamese Column
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _shuffledVietnamese.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _shuffledVietnamese[index];
                    final isMatched = widget.exercise.pairs.any(
                      (p) =>
                          _matchedPairs.contains(p.english) &&
                          p.vietnamese == item,
                    );
                    final isSelected = _selectedVi == item;
                    final isWrong = _wrongVi == item;

                    return _PairCard(
                      text: item,
                      isMatched: isMatched,
                      isSelected: isSelected,
                      isWrong: isWrong,
                      onTap: () => _selectVietnamese(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PairCard extends StatelessWidget {
  final String text;
  final bool isMatched;
  final bool isSelected;
  final bool isWrong;
  final VoidCallback onTap;

  const _PairCard({
    required this.text,
    required this.isMatched,
    required this.isSelected,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = AppColors.outline.withValues(alpha: 0.15);
    Color textColor = AppColors.textPrimary;

    if (isMatched) {
      bgColor = AppColors.primaryLight.withValues(alpha: 0.4);
      borderColor = AppColors.primary.withValues(alpha: 0.3);
      textColor = AppColors.textHint;
    } else if (isWrong) {
      bgColor = AppColors.error.withValues(alpha: 0.1);
      borderColor = AppColors.error;
      textColor = AppColors.error;
    } else if (isSelected) {
      bgColor = AppColors.primaryLight;
      borderColor = AppColors.primaryDark;
      textColor = AppColors.primaryDark;
    }

    return InkWell(
      onTap: isMatched ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: borderColor,
            width: isSelected || isWrong ? 2.5 : 1.5,
          ),
          boxShadow: isMatched
              ? []
              : [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected || isMatched
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: textColor,
                  decoration: isMatched ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isMatched) ...[
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.circleCheck,
                color: AppColors.primaryDark,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
