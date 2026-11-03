import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_models.dart';

/// Giao diện 08 – Bài tập Nghe & Điền từ
/// Hiển thị câu hỏi, nút nghe (chuẩn + chậm), ô nhập câu trả lời.
class ListeningExerciseWidget extends StatefulWidget {
  final ListeningExercise exercise;
  final ValueChanged<String> onAnswerChanged;

  const ListeningExerciseWidget({
    super.key,
    required this.exercise,
    required this.onAnswerChanged,
  });

  @override
  State<ListeningExerciseWidget> createState() =>
      _ListeningExerciseWidgetState();
}

class _ListeningExerciseWidgetState extends State<ListeningExerciseWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  // Trạng thái phát âm thanh (mô phỏng)
  bool _isPlaying = false;
  bool _isPlayingSlow = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Giả lập phát âm chuẩn (sẽ gọi TTS/audioplayers sau khi tích hợp API)
  Future<void> _playNormal() async {
    if (_isPlaying || _isPlayingSlow) return;
    setState(() => _isPlaying = true);
    // TODO: gọi TTS với widget.exercise.audioText
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _isPlaying = false);
  }

  /// Giả lập phát âm chậm 0.6x
  Future<void> _playSlow() async {
    if (_isPlaying || _isPlayingSlow) return;
    setState(() => _isPlayingSlow = true);
    // TODO: gọi TTS tốc độ chậm với widget.exercise.audioText
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _isPlayingSlow = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Tiêu đề câu hỏi
        Text(
          widget.exercise.prompt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 28),

        // Khu vực nút phát âm
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Icon micro to ở trung tâm
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isPlaying
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? LucideIcons.audioLines : LucideIcons.volume2,
                  color: AppColors.primaryDark,
                  size: 34,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Nghe câu và điền vào ô bên dưới',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Hai nút nghe
              Row(
                children: [
                  // Nút nghe chuẩn
                  Expanded(
                    flex: 3,
                    child: _AudioButton(
                      label: 'Nghe câu mẫu',
                      icon: LucideIcons.play,
                      isActive: _isPlaying,
                      isPrimary: true,
                      onTap: _playNormal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Nút nghe chậm
                  Expanded(
                    flex: 2,
                    child: _AudioButton(
                      label: 'Chậm hơn',
                      icon: LucideIcons.rabbit, // icon con rùa tương trưng slow
                      isActive: _isPlayingSlow,
                      isPrimary: false,
                      onTap: _playSlow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Ô nhập câu trả lời
        Text(
          'Nhập câu bạn vừa nghe:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: widget.onAnswerChanged,
          autofocus: false,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Gõ câu bạn nghe được...',
            prefixIcon: const Icon(
              LucideIcons.pencilLine,
              color: AppColors.textHint,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AudioButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: isActive ? null : onTap,
              icon: isActive
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: isActive ? null : onTap,
              icon: isActive
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryDark,
                      ),
                    )
                  : Icon(icon, size: 16, color: AppColors.primaryDark),
              label: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
            ),
    );
  }
}

