import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:mocktail/mocktail.dart';

class MockSoundPlayer extends Mock implements SoundPlayer {}

class MockChessAi extends Mock implements ChessAi {}

class MockGameRepository extends Mock implements GameRepository {}

/// Gọi một lần trong `setUpAll` của file test có dùng `any()` cho [SoundEffect] hay [AiLevel].
void registerFallbacks() {
  registerFallbackValue(SoundEffect.move);
  registerFallbackValue(AiLevel.medium);
  registerFallbackValue(const Move(0, 0));
  registerFallbackValue(
    const SavedGame(startFen: Fen.initial, moves: [], config: GameConfig.pvp()),
  );
}
