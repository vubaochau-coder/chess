import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/move.dart';
import 'package:mocktail/mocktail.dart';

class MockSoundPlayer extends Mock implements SoundPlayer {}

class MockChessAi extends Mock implements ChessAi {}

/// Gọi một lần trong `setUpAll` của file test có dùng `any()` cho [SoundEffect] hay [AiLevel].
void registerFallbacks() {
  registerFallbackValue(SoundEffect.move);
  registerFallbackValue(AiLevel.medium);
  registerFallbackValue(const Move(0, 0));
}
