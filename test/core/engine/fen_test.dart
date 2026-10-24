import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/square.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fen round-trip', () {
    const fens = [
      // 1. Initial position
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      // 2. After 1. e4
      'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      // 3. Kiwipete
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
      // 4. Perft #3 endgame
      '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
      // 5. Position without castling rights
      'r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1',
      // 6. Position with fullmoveNumber > 1
      'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
    ];

    for (final fen in fens) {
      test('round-trip for $fen', () {
        final pos = Fen.parse(fen);
        expect(Fen.format(pos), fen);
      });
    }

    test('parse 4-field FEN defaults clocks to 0 and 1', () {
      const fen4 = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -';
      final pos = Fen.parse(fen4);
      expect(pos.halfmoveClock, 0);
      expect(pos.fullmoveNumber, 1);
      expect(
        Fen.format(pos),
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
    });
  });

  group('Fen format validation errors', () {
    test('invalid number of ranks (not 8)', () {
      // 7 ranks
      expect(
        () =>
            Fen.parse('rnbqkbnr/pppppppp/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'),
        throwsFormatException,
      );
      // 9 ranks
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
    });

    test('rank has too few or too many squares', () {
      // Row has 7 squares
      expect(
        () => Fen.parse(
          'rnbqkbnr/ppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
      // Row has 9 squares
      expect(
        () => Fen.parse(
          'rnbqkbnr/ppppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
    });

    test('consecutive digits throw FormatException', () {
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/44/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/17/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/116/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
    });

    test('unknown character in board', () {
      expect(
        () => Fen.parse(
          'rnbqkbnr/ppppXppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
    });

    test('invalid active color', () {
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1',
        ),
        throwsFormatException,
      );
    });

    test('invalid or duplicate castling character', () {
      // Invalid character 'X'
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQx - 0 1',
        ),
        throwsFormatException,
      );
      // Duplicate 'K'
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KKq - 0 1',
        ),
        throwsFormatException,
      );
    });

    test('en passant square not on rank 3 or 6', () {
      // Rank 4
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e4 0 1',
        ),
        throwsFormatException,
      );
      // Rank 5
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e5 0 1',
        ),
        throwsFormatException,
      );
    });

    test('invalid clocks', () {
      // Halfmove clock < 0
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - -1 1',
        ),
        throwsFormatException,
      );
      // Halfmove clock not integer
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - abc 1',
        ),
        throwsFormatException,
      );
      // Fullmove number < 1
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0',
        ),
        throwsFormatException,
      );
      // Fullmove number not integer
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 xyz',
        ),
        throwsFormatException,
      );
    });

    test('each side must have exactly 1 king', () {
      // White has 2 kings
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBKKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
      // Black has 0 kings
      expect(
        () => Fen.parse(
          'rnbqqbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
        throwsFormatException,
      );
    });

    test('invalid number of fields', () {
      expect(
        () => Fen.parse('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq'),
        throwsFormatException,
      );
      expect(
        () => Fen.parse(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 2',
        ),
        throwsFormatException,
      );
    });
  });

  group('Clocks behavior in ChessRules.applyMove', () {
    test('after 1.e4 -> halfmove 0, fullmove 1, black to move; after 1...Nf6 -> 1 2; after capture -> halfmove 0', () {
      var pos = GamePosition.initial();
      expect(pos.halfmoveClock, 0);
      expect(pos.fullmoveNumber, 1);
      expect(pos.whiteToMove, isTrue);

      // 1. e4 (e2 to e4: squareFromName('e2') -> squareFromName('e4'))
      final e2 = squareFromName('e2');
      final e4 = squareFromName('e4');
      pos = ChessRules.applyMove(pos, e2, e4).position;

      expect(pos.whiteToMove, isFalse);
      expect(pos.halfmoveClock, 0); // pawn move resets halfmove
      expect(pos.fullmoveNumber, 1);
      expect(pos.enPassant, squareFromName('e3'));

      // 1... Nf6 (g8 to f6)
      final g8 = squareFromName('g8');
      final f6 = squareFromName('f6');
      pos = ChessRules.applyMove(pos, g8, f6).position;

      expect(pos.whiteToMove, isTrue);
      expect(
        pos.halfmoveClock,
        1,
      ); // knight move (non-pawn, non-capture) increments
      expect(
        pos.fullmoveNumber,
        2,
      ); // Black move finished, fullmove incremented

      // 2. a3 (pawn move resets halfmove)
      final a2 = squareFromName('a2');
      final a3 = squareFromName('a3');
      pos = ChessRules.applyMove(pos, a2, a3).position;
      expect(pos.halfmoveClock, 0);
      expect(pos.fullmoveNumber, 2);

      // 2... a6 (pawn move resets halfmove)
      final a7 = squareFromName('a7');
      final a6 = squareFromName('a6');
      pos = ChessRules.applyMove(pos, a7, a6).position;
      expect(pos.halfmoveClock, 0);
      expect(pos.fullmoveNumber, 3);

      // 3. h3 (non-capture pawn move resets)
      final h2 = squareFromName('h2');
      final h3 = squareFromName('h3');
      pos = ChessRules.applyMove(pos, h2, h3).position;
      expect(pos.halfmoveClock, 0);

      // 3... Nxe4 (knight captures pawn on e4 -> halfmove resets to 0)
      final moveCapture = ChessRules.applyMove(pos, f6, e4);
      expect(moveCapture.isCapture, isTrue);
      pos = moveCapture.position;
      expect(pos.halfmoveClock, 0); // capture resets halfmove
      expect(pos.fullmoveNumber, 4);
    });
  });
}
