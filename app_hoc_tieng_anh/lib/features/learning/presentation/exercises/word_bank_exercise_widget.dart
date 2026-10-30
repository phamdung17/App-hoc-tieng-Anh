import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_models.dart';

class WordBankExerciseWidget extends StatefulWidget {
  final WordBankExercise exercise;
  final ValueChanged<List<String>> onAnswerChanged;

  const WordBankExerciseWidget({
    super.key,
    required this.exercise,
    required this.onAnswerChanged,
  });

  @override
  State<WordBankExerciseWidget> createState() => _WordBankExerciseWidgetState();
}

class _WordBankExerciseWidgetState extends State<WordBankExerciseWidget> {
  late List<String> _bankWords;
  final List<String> _selectedWords = [];

  @override
  void initState() {
    super.initState();
    _bankWords = List.from(widget.exercise.availableWords);
  }

  @override
  void didUpdateWidget(covariant WordBankExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _bankWords = List.from(widget.exercise.availableWords);
      _selectedWords.clear();
    }
  }

  void _pickWord(String word) {
    setState(() {
      _bankWords.remove(word);
      _selectedWords.add(word);
    });
    widget.onAnswerChanged(_selectedWords);
  }

  void _returnWord(String word) {
    setState(() {
      _selectedWords.remove(word);
      _bankWords.add(word);
    });
    widget.onAnswerChanged(_selectedWords);
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
        const SizedBox(height: 14),

        // Vietnamese Sentence Card with Avatar / Mascot
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.12), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🦉', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.exercise.vietnameseSentence,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Answer Slot Area
        Container(
          constraints: const Duration(milliseconds: 300) > Duration.zero
              ? const BoxConstraints(minHeight: 110)
              : null,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: _selectedWords.isEmpty
              ? const Center(
                  child: Text(
                    'Chạm từ bên dưới để ghép vào đây',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedWords.map((word) {
                    return _WordChip(
                      word: word,
                      isSelected: true,
                      onTap: () => _returnWord(word),
                    );
                  }).toList(),
                ),
        ),

        const Spacer(),

        // Divider
        const Divider(color: AppColors.divider, height: 32),

        // Word Bank Area
        Text(
          'Ngân hàng từ vựng:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _bankWords.map((word) {
            return _WordChip(
              word: word,
              isSelected: false,
              onTap: () => _pickWord(word),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final bool isSelected;
  final VoidCallback onTap;

  const _WordChip({
    required this.word,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(
              color: isSelected ? AppColors.primaryDark : AppColors.outline.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

