import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class _ChallengeQuestion {
  final String word;
  final String pronunciation;
  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String example;

  const _ChallengeQuestion({
    required this.word,
    required this.pronunciation,
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.example,
  });
}

class DailyChallengePage extends StatefulWidget {
  const DailyChallengePage({super.key});

  @override
  State<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends State<DailyChallengePage> {
  // Bộ câu hỏi mẫu chạy offline; có thể thay bằng dữ liệu từ API sau này.
  static const _questions = [
    _ChallengeQuestion(
      word: 'generous',
      pronunciation: '/ˈdʒenərəs/',
      prompt: 'Từ này có nghĩa là gì?',
      options: ['rộng lượng', 'lo lắng', 'ồn ào', 'kiên nhẫn'],
      answerIndex: 0,
      example: 'She is generous with her time.',
    ),
    _ChallengeQuestion(
      word: 'borrow',
      pronunciation: '/ˈbɒrəʊ/',
      prompt: 'Chọn nghĩa đúng của từ:',
      options: ['cho mượn', 'mượn', 'mua', 'bán'],
      answerIndex: 1,
      example: 'Can I borrow your pen?',
    ),
    _ChallengeQuestion(
      word: 'improve',
      pronunciation: '/ɪmˈpruːv/',
      prompt: 'Từ này có nghĩa là gì?',
      options: ['quên', 'giải thích', 'cải thiện', 'chuẩn bị'],
      answerIndex: 2,
      example: 'Practice helps you improve your English.',
    ),
    _ChallengeQuestion(
      word: 'crowded',
      pronunciation: '/ˈkraʊdɪd/',
      prompt: 'Chọn nghĩa đúng của từ:',
      options: ['yên tĩnh', 'vắng vẻ', 'thoải mái', 'đông đúc'],
      answerIndex: 3,
      example: 'The bus is crowded in the morning.',
    ),
    _ChallengeQuestion(
      word: 'arrive',
      pronunciation: '/əˈraɪv/',
      prompt: 'Từ này có nghĩa là gì?',
      options: ['rời đi', 'đến nơi', 'đợi', 'bắt đầu'],
      answerIndex: 1,
      example: 'We arrive at school before eight.',
    ),
  ];

  int _questionIndex = 0;
  int? _selectedOption;
  int _score = 0;
  bool _isAnswerChecked = false;

  _ChallengeQuestion get _question => _questions[_questionIndex];

  void _checkAnswer() {
    if (_selectedOption == null || _isAnswerChecked) return;

    setState(() {
      _isAnswerChecked = true;
      // Chỉ cộng điểm một lần sau khi người học xác nhận đáp án.
      if (_selectedOption == _question.answerIndex) _score++;
    });
  }

  void _goToNextQuestion() {
    if (!_isAnswerChecked) return;

    setState(() {
      _questionIndex++;
      _selectedOption = null;
      _isAnswerChecked = false;
    });
  }

  void _restartChallenge() {
    setState(() {
      _questionIndex = 0;
      _selectedOption = null;
      _score = 0;
      _isAnswerChecked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _questionIndex == _questions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Thử thách hôm nay'), centerTitle: true),
      body: SafeArea(child: isComplete ? _buildResult() : _buildQuestion()),
    );
  }

  Widget _buildQuestion() {
    final question = _question;
    final isCorrect = _selectedOption == question.answerIndex;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_questionIndex + 1) / _questions.length,
                  minHeight: 8,
                  backgroundColor: AppColors.primaryLight,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_questionIndex + 1}/${_questions.length}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            children: [
              Text(
                question.prompt,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                question.word,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                question.pronunciation,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (var index = 0; index < question.options.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOption(index, question.options[index]),
          ),
        if (_isAnswerChecked) ...[
          const SizedBox(height: 4),
          Text(
            isCorrect
                ? 'Chính xác! ${question.word} nghĩa là "${question.options[question.answerIndex]}".'
                : 'Chưa đúng. Đáp án là "${question.options[question.answerIndex]}".',
            style: TextStyle(
              color: isCorrect ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.example,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isAnswerChecked
                ? _goToNextQuestion
                : _selectedOption == null
                ? null
                : _checkAnswer,
            child: Text(
              _isAnswerChecked
                  ? _questionIndex == _questions.length - 1
                        ? 'Xem kết quả'
                        : 'Câu tiếp theo'
                  : 'Kiểm tra',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(int index, String option) {
    final isSelected = _selectedOption == index;
    final isCorrectOption = index == _question.answerIndex;
    final backgroundColor = !_isAnswerChecked
        ? isSelected
              ? AppColors.primaryLight
              : AppColors.surface
        : isCorrectOption
        ? AppColors.primaryLight
        : isSelected
        ? const Color(0xFFFFECEA)
        : AppColors.surface;
    final borderColor = !_isAnswerChecked && isSelected
        ? AppColors.primaryDark
        : _isAnswerChecked && isCorrectOption
        ? AppColors.success
        : _isAnswerChecked && isSelected
        ? AppColors.error
        : AppColors.divider;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: _isAnswerChecked
            ? null
            : () => setState(() => _selectedOption = index),
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isAnswerChecked && isCorrectOption)
                const Icon(Icons.check_circle, color: AppColors.success)
              else if (_isAnswerChecked && isSelected)
                const Icon(Icons.cancel, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final message = switch (_score) {
      5 => 'Xuất sắc! Bạn đã nắm vững các từ hôm nay.',
      >= 3 => 'Làm tốt lắm! Hãy tiếp tục luyện tập nhé.',
      _ => 'Đừng nản lòng, thử lại để ghi nhớ lâu hơn nhé.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.warning,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành thử thách!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_score/${_questions.length} câu đúng',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _restartChallenge,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
