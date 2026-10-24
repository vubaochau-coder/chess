import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IsolateChessAi', () {
    test('returns a legal move from starting position', () async {
      const ai = IsolateChessAi(minDelay: Duration.zero);
      final initial = GamePosition.initial();
      final move = await ai.chooseMove([initial], AiLevel.easy);

      final legalDestinations = ChessRules.legalMoves(initial, move.from);
      expect(legalDestinations.contains(move.to), isTrue);
    });

    test('finds mate in 1 across isolate', () async {
      const ai = IsolateChessAi(minDelay: Duration.zero);
      // Back-rank mate: Rd8#
      final pos = Fen.parse('6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');
      final move = await ai.chooseMove([pos], AiLevel.medium);

      expect(move.toUci(), equals('d1d8'));
    });

    test('execution takes at least 400ms by default', () async {
      const ai = IsolateChessAi();
      final initial = GamePosition.initial();
      final sw = Stopwatch()..start();
      final move = await ai.chooseMove([initial], AiLevel.easy);
      sw.stop();

      expect(move, isNotNull);
      // Cho phép sai số biên nhỏ đo đạc 390ms
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(390));
    });
  });
}
