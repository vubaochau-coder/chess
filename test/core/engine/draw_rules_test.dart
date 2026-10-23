import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Insufficient material', () {
    test('K vs K is insufficient material', () {
      final pos = Fen.parse('8/8/8/4k3/8/8/4K3/8 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(pos.board), isTrue);
      expect(ChessRules.gameStatus([pos]), GameStatus.drawInsufficientMaterial);
    });

    test('K+B vs K is insufficient material', () {
      final posW = Fen.parse('8/8/8/4k3/8/5B2/4K3/8 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(posW.board), isTrue);
      expect(
        ChessRules.gameStatus([posW]),
        GameStatus.drawInsufficientMaterial,
      );

      final posB = Fen.parse('8/8/8/4k3/5b2/8/4K3/8 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(posB.board), isTrue);
      expect(
        ChessRules.gameStatus([posB]),
        GameStatus.drawInsufficientMaterial,
      );
    });

    test('K+N vs K is insufficient material', () {
      final posW = Fen.parse('8/8/8/4k3/8/5N2/4K3/8 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(posW.board), isTrue);
      expect(
        ChessRules.gameStatus([posW]),
        GameStatus.drawInsufficientMaterial,
      );

      final posB = Fen.parse('8/8/8/4k3/5n2/8/4K3/8 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(posB.board), isTrue);
      expect(
        ChessRules.gameStatus([posB]),
        GameStatus.drawInsufficientMaterial,
      );
    });

    test('bishops on the same square color is insufficient material', () {
      // Both bishops on light squares (c1 is dark: (7+2)%2 = 1? Let's check:
      // a8: 0+0=0, b8: 0+1=1, c8: 0+2=0 light
      // c1: 7+2=9 (1). d2: 6+3=9 (1). Both have squareColor = 1.
      final pos = Fen.parse('8/8/8/4k3/8/8/3bK3/2B5 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(pos.board), isTrue);
      expect(ChessRules.gameStatus([pos]), GameStatus.drawInsufficientMaterial);
    });

    test('bishops on different square colors is NOT insufficient material', () {
      // c1: (7+2)%2 = 1. c2: (6+2)%2 = 0.
      final pos = Fen.parse('8/8/8/4k3/8/8/2b1K3/2B5 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(pos.board), isFalse);
      expect(ChessRules.gameStatus([pos]), GameStatus.playing);
    });

    test('K+N+N vs K is NOT insufficient material', () {
      final pos = Fen.parse('8/8/8/4k3/8/5NN1/4K3/8 w - - 0 1');
      expect(ChessRules.isInsufficientMaterial(pos.board), isFalse);
      expect(ChessRules.gameStatus([pos]), GameStatus.playing);
    });

    test('positions with pawns or rooks or queens are NOT insufficient', () {
      expect(
        ChessRules.isInsufficientMaterial(
          Fen.parse('8/8/8/4k3/8/8/4P3/4K3 w - - 0 1').board,
        ),
        isFalse,
      );
      expect(
        ChessRules.isInsufficientMaterial(
          Fen.parse('8/8/8/4k3/8/8/4R3/4K3 w - - 0 1').board,
        ),
        isFalse,
      );
      expect(
        ChessRules.isInsufficientMaterial(
          Fen.parse('8/8/8/4k3/8/8/4Q3/4K3 w - - 0 1').board,
        ),
        isFalse,
      );
    });
  });

  group('Fifty-move rule', () {
    test('drawFiftyMove when halfmoveClock >= 100', () {
      final pos = Fen.parse('8/8/8/4k3/8/8/4K3/R7 w - - 100 50');
      expect(ChessRules.gameStatus([pos]), GameStatus.drawFiftyMove);
    });

    test(
      'checkmate takes precedence over fifty-move rule at 100 halfmoves',
      () {
        // Qh7# on black king on h8
        final pos = Fen.parse('7k/7Q/6K1/8/8/8/8/8 b - - 100 50');
        expect(ChessRules.gameStatus([pos]), GameStatus.checkmate);
      },
    );

    test('stalemate takes precedence over fifty-move rule', () {
      final pos = Fen.parse('7k/5Q2/6K1/8/8/8/8/8 b - - 100 50');
      expect(ChessRules.gameStatus([pos]), GameStatus.stalemate);
    });
  });

  group('Threefold repetition', () {
    test(
      'repetition by moving knights back and forth (Nf3 Nf6 Ng1 Ng8 x2)',
      () {
        final history = <GamePosition>[GamePosition.initial()];

        // 1. Nf3 Nf6
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('g1'),
            squareFromName('f3'),
          ).position,
        );
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('g8'),
            squareFromName('f6'),
          ).position,
        );

        // 2. Ng1 Ng8 (position key 2nd time)
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('f3'),
            squareFromName('g1'),
          ).position,
        );
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('f6'),
            squareFromName('g8'),
          ).position,
        );
        expect(ChessRules.gameStatus(history), GameStatus.playing);

        // 3. Nf3 Nf6
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('g1'),
            squareFromName('f3'),
          ).position,
        );
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('g8'),
            squareFromName('f6'),
          ).position,
        );

        // 4. Ng1 Ng8 (position key 3rd time -> drawRepetition)
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('f3'),
            squareFromName('g1'),
          ).position,
        );
        history.add(
          ChessRules.applyMove(
            history.last,
            squareFromName('f6'),
            squareFromName('g8'),
          ).position,
        );

        expect(ChessRules.gameStatus(history), GameStatus.drawRepetition);
      },
    );

    test('en passant square difference does not prevent repetition if en passant cannot be captured', () {
      // Position with rooks so it is not insufficient material
      // White to move, enPassant target h6 exists in p2, but White has no pawn to capture on h6
      final p1 = Fen.parse('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      final p2 = Fen.parse('r3k3/8/8/8/8/8/8/R3K3 w - h6 0 2');
      final p3 = Fen.parse('r3k3/8/8/8/8/8/8/R3K3 w - - 2 3');

      final history = [p1, p2, p3];
      expect(ChessRules.gameStatus(history), GameStatus.drawRepetition);
    });
  });
}
