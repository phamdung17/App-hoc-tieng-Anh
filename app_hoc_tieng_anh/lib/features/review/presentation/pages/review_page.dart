import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final List<Map<String, String>> _flashcards = [
    {
      'en': 'Delicious',
      'ipa': '/dɪˈlɪʃ.əs/',
      'vi': 'Ngon miệng, thơm ngon',
      'example': 'This food is very delicious.',
    },
    {
      'en': 'Station',
      'ipa': '/ˈsteɪ.ʃən/',
      'vi': 'Nhà ga, bến đỗ',
      'example': 'Where is the nearest train station?',
    },
    {
      'en': 'Appointment',
      'ipa': '/əˈpɔɪnt.mənt/',
      'vi': 'Cuộc hẹn, cuộc gặp',
      'example': 'I have an appointment at 10 AM.',
    },
  ];

  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _quizMode = false;
  int? _answer;

  void _nextCard() {
    setState(() {
      _isFlipped = false;
      _answer = null;
      _currentIndex = (_currentIndex + 1) % _flashcards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _flashcards[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _quizMode ? 'Quiz từ vựng' : 'Flashcard',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            Text(
              'Thẻ ${_currentIndex + 1} / ${_flashcards.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Flashcard'),
                  icon: Icon(LucideIcons.layers),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Quiz'),
                  icon: Icon(LucideIcons.listChecks),
                ),
              ],
              selected: {_quizMode},
              onSelectionChanged: (value) => setState(() {
                _quizMode = value.first;
                _answer = null;
                _isFlipped = false;
              }),
            ),
            const SizedBox(height: 12),
            if (_quizMode) ...[
              Text(
                '“${card['vi']}” tiếng Anh là gì?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              for (final (index, option) in [
                '${card['en']}',
                'Hello',
                'Book',
                'Water',
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: () => setState(() => _answer = index),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _answer == index
                          ? AppColors.primaryLight
                          : Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(option),
                  ),
                ),
              if (_answer != null)
                Text(
                  _answer == 0
                      ? 'Chính xác!'
                      : 'Chưa đúng, đáp án là ${card['en']}.',
                  style: TextStyle(
                    color: _answer == 0 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _answer == null ? null : _nextCard,
                child: const Text('CÂU TIẾP THEO'),
              ),
            ] else ...[
              // Flippable Card
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isFlipped = !_isFlipped),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isFlipped ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.panel),
                      border: Border.all(
                        color: _isFlipped
                            ? AppColors.primary
                            : AppColors.outline.withValues(alpha: 0.12),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isFlipped
                              ? 'MẶT SAU (NGHĨA TIẾNG VIỆT)'
                              : 'MẶT TRƯỚC (TIẾNG ANH)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _isFlipped
                                ? AppColors.primaryDark
                                : AppColors.textHint,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isFlipped ? card['vi']! : card['en']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _isFlipped
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isFlipped
                              ? 'Ví dụ: "${card['example']}"'
                              : card['ipa']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.hand,
                              size: 18,
                              color: _isFlipped
                                  ? AppColors.primaryDark
                                  : AppColors.textHint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Chạm vào thẻ để lật',
                              style: TextStyle(
                                fontSize: 13,
                                color: _isFlipped
                                    ? AppColors.primaryDark
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Rating Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFECEB),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                      ),
                      child: const Text(
                        'CẦN ÔN LẠI',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                      ),
                      child: const Text(
                        'ĐÃ NHỚ TỐT',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}
