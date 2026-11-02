import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSoundEffect { click, correct, incorrect, lessonComplete }

/// Central playback and persisted sound-effects preference.
class AppSoundEffects {
  AppSoundEffects._();

  static final instance = AppSoundEffects._();
  static const _enabledKey = 'sound_effects_enabled';

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> enabled = ValueNotifier(true);
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _loadPreference();

  Future<void> _loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    enabled.value = preferences.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    await initialize();
    enabled.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, value);
    if (value) await play(AppSoundEffect.click);
  }

  Future<void> play(AppSoundEffect effect) async {
    await initialize();
    if (!enabled.value) return;

    final file = switch (effect) {
      AppSoundEffect.click => 'click.mp3',
      AppSoundEffect.correct => 'success.mp3',
      AppSoundEffect.incorrect => 'error.mp3',
      AppSoundEffect.lessonComplete => 'success.mp3',
    };
    try {
      await _player.stop();
      await _player.setVolume(effect == AppSoundEffect.click ? 0.24 : 0.34);
      await _player.play(AssetSource('audio/sfx/$file'));
    } catch (_) {
      // Audio feedback must never interrupt the learning flow.
    }
  }
}
