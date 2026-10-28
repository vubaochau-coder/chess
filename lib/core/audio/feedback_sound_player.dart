import 'dart:async';

import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:flutter/services.dart';

enum HapticKind { selection, light, medium }

final class FeedbackSoundPlayer implements SoundPlayer {
  FeedbackSoundPlayer(
    this._inner, {
    required AppSettings Function() readSettings,
    void Function(HapticKind kind)? haptic,
  }) : _readSettings = readSettings,
       _haptic = haptic ?? _systemHaptic;

  final SoundPlayer _inner;
  final AppSettings Function() _readSettings;
  final void Function(HapticKind kind) _haptic;

  static HapticKind? hapticFor(SoundEffect effect) => switch (effect) {
    SoundEffect.select => HapticKind.selection,
    SoundEffect.move ||
    SoundEffect.castle ||
    SoundEffect.promote => HapticKind.light,
    SoundEffect.capture ||
    SoundEffect.check ||
    SoundEffect.gameEnd => HapticKind.medium,
    SoundEffect.illegal => null,
  };

  @override
  void play(SoundEffect effect, {double volume = 1.0}) {
    final settings = _readSettings();
    if (settings.soundEnabled) {
      _inner.play(effect, volume: volume * settings.soundVolume);
    }
    final kind = hapticFor(effect);
    if (settings.hapticsEnabled && kind != null) {
      _haptic(kind);
    }
  }

  @override
  Future<void> dispose() => _inner.dispose();

  static void _systemHaptic(HapticKind kind) {
    switch (kind) {
      case HapticKind.selection:
        unawaited(HapticFeedback.selectionClick());
      case HapticKind.light:
        unawaited(HapticFeedback.lightImpact());
      case HapticKind.medium:
        unawaited(HapticFeedback.mediumImpact());
    }
  }
}
