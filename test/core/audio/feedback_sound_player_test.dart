import 'package:chess/core/audio/feedback_sound_player.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockSoundPlayer inner;
  late List<HapticKind> haptics;
  late AppSettings settings;

  FeedbackSoundPlayer buildPlayer() => FeedbackSoundPlayer(
    inner,
    readSettings: () => settings,
    haptic: haptics.add,
  );

  setUp(() {
    inner = MockSoundPlayer();
    haptics = [];
    settings = const AppSettings();
  });

  group('FeedbackSoundPlayer', () {
    test('plays through the inner player with the configured volume', () {
      settings = const AppSettings(soundVolume: 0.5);

      buildPlayer().play(SoundEffect.move);

      verify(() => inner.play(SoundEffect.move, volume: 0.5)).called(1);
    });

    test('does not play when sound is disabled', () {
      settings = const AppSettings(soundEnabled: false);

      buildPlayer().play(SoundEffect.capture);

      verifyNever(() => inner.play(any(), volume: any(named: 'volume')));
    });

    test('vibrates with the kind mapped to each effect', () {
      final player = buildPlayer();
      for (final effect in SoundEffect.values) {
        player.play(effect);
      }

      expect(haptics, [
        HapticKind.selection,
        HapticKind.light,
        HapticKind.medium,
        HapticKind.light,
        HapticKind.medium,
        HapticKind.light,
        HapticKind.medium,
      ]);
    });

    test('does not vibrate for illegal moves or when haptics are off', () {
      buildPlayer().play(SoundEffect.illegal);
      expect(haptics, isEmpty);

      settings = const AppSettings(hapticsEnabled: false);
      buildPlayer().play(SoundEffect.capture);
      expect(haptics, isEmpty);
    });

    test('dispose disposes the inner player', () async {
      when(inner.dispose).thenAnswer((_) async {});

      await buildPlayer().dispose();

      verify(inner.dispose).called(1);
    });
  });
}
