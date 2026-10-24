import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedGame', () {
    test('serializes and deserializes valid SavedGame (PvE)', () {
      const saved = SavedGame(
        startFen: Fen.initial,
        moves: ['e2e4', 'e7e5', 'g1f3'],
        config: GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.white,
          level: AiLevel.hard,
        ),
      );

      final json = saved.toJson();
      expect(json['version'], 1);
      expect(json['startFen'], Fen.initial);
      expect(json['moves'], ['e2e4', 'e7e5', 'g1f3']);
      expect(json['mode'], 'pve');
      expect(json['humanColor'], 'white');
      expect(json['level'], 'hard');

      final encoded = saved.encode();
      final decoded = SavedGame.decode(encoded);
      expect(decoded, saved);
    });

    test('serializes and deserializes valid SavedGame (PvP)', () {
      const saved = SavedGame(
        startFen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        moves: ['e7e5'],
        config: GameConfig.pvp(),
      );

      final encoded = saved.encode();
      final decoded = SavedGame.decode(encoded);
      expect(decoded.config.mode, GameMode.pvp);
      expect(decoded.moves, ['e7e5']);
    });

    test('throws FormatException on version != 1', () {
      expect(
        () => SavedGame.decode(
          '{"version": 2, "startFen": "${Fen.initial}", "moves": [], "mode": "pvp", "humanColor": "white", "level": "medium"}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid startFen', () {
      expect(
        () => SavedGame.decode(
          '{"version": 1, "startFen": 123, "moves": [], "mode": "pvp", "humanColor": "white", "level": "medium"}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid moves', () {
      expect(
        () => SavedGame.decode(
          '{"version": 1, "startFen": "${Fen.initial}", "moves": "e2e4", "mode": "pvp", "humanColor": "white", "level": "medium"}',
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SavedGame.decode(
          '{"version": 1, "startFen": "${Fen.initial}", "moves": [123], "mode": "pvp", "humanColor": "white", "level": "medium"}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid mode', () {
      expect(
        () => SavedGame.decode(
          '{"version": 1, "startFen": "${Fen.initial}", "moves": [], "mode": "online", "humanColor": "white", "level": "medium"}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid humanColor', () {
      expect(
        () => SavedGame.decode(
          '{"version": 1, "startFen": "${Fen.initial}", "moves": [], "mode": "pve", "humanColor": "green", "level": "medium"}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid level', () {
      expect(
        () => SavedGame.decode(
          '{"version": 1, "startFen": "${Fen.initial}", "moves": [], "mode": "pve", "humanColor": "white", "level": "impossible"}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on non-object JSON', () {
      expect(
        () => SavedGame.decode('"just a string"'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
