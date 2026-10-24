import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameConfig', () {
    test('default values and constructor', () {
      const config = GameConfig(mode: GameMode.pve);
      expect(config.mode, GameMode.pve);
      expect(config.humanColor, PieceColor.white);
      expect(config.level, AiLevel.medium);
    });

    test('pvp constructor defaults', () {
      const pvp = GameConfig.pvp();
      expect(pvp.mode, GameMode.pvp);
      expect(pvp.humanColor, PieceColor.white);
      expect(pvp.level, AiLevel.medium);
    });

    test('props equality', () {
      const config1 = GameConfig(
        mode: GameMode.pve,
        humanColor: PieceColor.black,
        level: AiLevel.hard,
      );
      const config2 = GameConfig(
        mode: GameMode.pve,
        humanColor: PieceColor.black,
        level: AiLevel.hard,
      );
      const config3 = GameConfig(
        mode: GameMode.pve,
        humanColor: PieceColor.white,
        level: AiLevel.hard,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });
}
