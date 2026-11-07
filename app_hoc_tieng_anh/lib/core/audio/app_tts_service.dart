// lib/core/audio/app_tts_service.dart
//
// Dịch vụ Text-to-Speech (TTS) phát âm chuẩn tiếng Anh:
// - Phát âm từ vựng đơn lẻ, câu ví dụ hoặc bài nghe.
// - Hỗ trợ tốc độ chuẩn (1.0x) và tốc độ chậm (0.7x) cho người mới bắt đầu.
// - Tích hợp cơ chế bảo vệ, tự động dừng audio đang chạy trước khi phát mới.

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AppTtsService {
  AppTtsService._();
  static final instance = AppTtsService._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);

  StreamSubscription<void>? _completionSubscription;

  void _init() {
    _completionSubscription ??= _player.onPlayerComplete.listen((_) {
      isSpeaking.value = false;
    });
  }

  /// Phát âm văn bản tiếng Anh [text]
  /// [slow]: nếu true sẽ phát ở tốc độ chậm (~0.7x)
  Future<void> speak(String text, {bool slow = false}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _init();

    try {
      isSpeaking.value = true;
      await _player.stop();

      // Đặt tốc độ phát âm
      await _player.setPlaybackRate(slow ? 0.72 : 1.0);

      // Encode query string cho Google Translate TTS engine
      final encoded = Uri.encodeComponent(clean);
      final url =
          'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=en&q=$encoded';

      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('AppTtsService.speak error: $e');
      isSpeaking.value = false;
    }
  }

  /// Dừng phát âm hiện tại
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    isSpeaking.value = false;
  }

  void dispose() {
    _completionSubscription?.cancel();
    _player.dispose();
  }
}
