import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:mocktail/mocktail.dart';

class MockSoundPlayer extends Mock implements SoundPlayer {}

/// Gọi một lần trong `setUpAll` của file test có dùng `any()` cho [SoundEffect].
void registerFallbacks() {
  registerFallbackValue(SoundEffect.move);
}
