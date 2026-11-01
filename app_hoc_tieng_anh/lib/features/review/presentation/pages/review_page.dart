import 'package:flutter/material.dart';
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

  void _nextCard() {
    setState(() {
      _isFlipped = false;
      _currentIndex = (_currentIndex + 1) % _flashcards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _flashcards[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ôn tập Flashcard SRS', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      color: _isFlipped ? AppColors.primary : AppColors.outline.withValues(alpha: 0.12),
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
                        _isFlipped ? 'MẶT SAU (NGHĨA TIẾNG VIỆT)' : 'MẶT TRƯỚC (TIẾNG ANH)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _isFlipped ? AppColors.primaryDark : AppColors.textHint,
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
                          color: _isFlipped ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isFlipped ? 'Ví dụ: "${card['example']}"' : card['ipa']!,
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
                            Icons.touch_app_rounded,
                            size: 18,
                            color: _isFlipped ? AppColors.primaryDark : AppColors.textHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chạm vào thẻ để lật',
                            style: TextStyle(
                              fontSize: 13,
                              color: _isFlipped ? AppColors.primaryDark : AppColors.textHint,
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
                    child: const Text('CẦN ÔN LẠI', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    child: const Text('ĐÃ NHỚ TỐT', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
