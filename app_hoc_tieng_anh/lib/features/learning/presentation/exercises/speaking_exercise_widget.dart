import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_models.dart';

/// Giao diện 09 – Bài tập Luyện phát âm (Speaking)
/// Hiển thị câu cần đọc, nút thu âm với hiệu ứng sóng âm, cho phép bỏ qua.
class SpeakingExerciseWidget extends StatefulWidget {
  final SpeakingExercise exercise;
  final VoidCallback onDone;

  const SpeakingExerciseWidget({
    super.key,
    required this.exercise,
    required this.onDone,
  });

  @override
  State<SpeakingExerciseWidget> createState() => _SpeakingExerciseWidgetState();
}

class _SpeakingExerciseWidgetState extends State<SpeakingExerciseWidget>
    with SingleTickerProviderStateMixin {
  _SpeakingState _state = _SpeakingState.idle;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _state = _SpeakingState.recording);
    // TODO: tích hợp speech_to_text / backend scoring
    // Giả lập ghi âm 3 giây
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _state = _SpeakingState.done);
  }

  void _retryRecording() {
    setState(() => _state = _SpeakingState.idle);
  }

  void _skip() {
    // Cho phép bỏ qua khi không tiện nói
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Tiêu đề
        Text(
          widget.exercise.prompt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Thẻ câu cần đọc
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                LucideIcons.quote,
                color: AppColors.primaryDark,
                size: 22,
              ),
              const SizedBox(height: 10),
              Text(
                widget.exercise.phrase,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Đọc câu này thành tiếng',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Nút thu âm / trạng thái
        Center(child: _buildRecordingArea(context)),

        const SizedBox(height: 24),

        // Nút Bỏ qua
        if (_state != _SpeakingState.done)
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Bỏ qua lần này',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),

        // Nút hoàn thành khi đã ghi âm xong
        if (_state == _SpeakingState.done) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retryRecording,
                  icon: const Icon(
                    LucideIcons.refreshCcw,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  label: const Text(
                    'Thử lại',
                    style: TextStyle(color: AppColors.primaryDark),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: widget.onDone,
                  icon: const Icon(LucideIcons.checkCircle, size: 20),
                  label: const Text('Hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecordingArea(BuildContext context) {
    switch (_state) {
      case _SpeakingState.idle:
        return _MicButton(
          onTap: _startRecording,
          isRecording: false,
          pulseAnimation: _pulseAnimation,
        );

      case _SpeakingState.recording:
        return Column(
          children: [
            _MicButton(
              onTap: () {},
              isRecording: true,
              pulseAnimation: _pulseAnimation,
            ),
            const SizedBox(height: 12),
            // Sóng âm giả lập
            _WaveformRow()
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 8),
            Text(
              'Đang ghi âm...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case _SpeakingState.done:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.checkCircle,
            color: AppColors.success,
            size: 40,
          ),
        ).animate().scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.elasticOut,
            );
    }
  }
}

enum _SpeakingState { idle, recording, done }

class _MicButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isRecording;
  final Animation<double> pulseAnimation;

  const _MicButton({
    required this.onTap,
    required this.isRecording,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isRecording ? pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color:
                    isRecording ? AppColors.error : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                isRecording ? LucideIcons.micOff : LucideIcons.mic,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget sóng âm giả lập khi đang ghi
class _WaveformRow extends StatelessWidget {
  final List<double> _heights = const [
    16, 28, 40, 22, 36, 12, 44, 30, 18, 38, 26, 14, 42, 24, 32,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_heights.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300 + i * 60),
              width: 5,
              height: _heights[i],
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.6 + (i % 3) * 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

