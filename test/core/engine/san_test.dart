import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/engine/san.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('San.format', () {
    test('1. Pawn move', () {
      final pos = Fen.parse(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(San.format(pos, Move.fromUci('e2e4')), 'e4');
    });

    test('2. Knight move', () {
      final pos = Fen.parse(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(San.format(pos, Move.fromUci('g1f3')), 'Nf3');
    });

    test('3. Bishop move', () {
      final pos = Fen.parse(
        'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      );
      expect(San.format(pos, Move.fromUci('f1c4')), 'Bc4');
    });

    test('4. Rook move', () {
      final pos = Fen.parse(
        'rnbqkbnr/1ppppppp/8/p7/R7/8/1PPPPPPP/1NBQKBNR w Kkq - 0 3',
      );
      expect(San.format(pos, Move.fromUci('a4a1')), 'Ra1');
    });

    test('5. Queen move', () {
      final pos = Fen.parse(
        'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      );
      expect(San.format(pos, Move.fromUci('d1h5')), 'Qh5');
    });

    test('6. King move', () {
      final pos = Fen.parse(
        'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPPKPPP/RNBQ1BNR w kq - 1 3',
      );
      expect(San.format(pos, Move.fromUci('e2e3')), 'Ke3');
    });

    test('7. Piece capture', () {
      final pos = Fen.parse(
        'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      );
      expect(San.format(pos, Move.fromUci('f1b5')), 'Bb5+');
      final capturePos = Fen.parse(
        'r1bqkbnr/ppp2ppp/2n5/3pp3/4P3/3B1N2/PPPP1PPP/RNBQK2R w KQkq - 0 4',
      );
      expect(San.format(capturePos, Move.fromUci('f3e5')), 'Nxe5');
    });

    test('8. Pawn capture', () {
      final pos = Fen.parse(
        'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      );
      expect(San.format(pos, Move.fromUci('e4d5')), 'exd5');
    });

    test('9. En passant capture', () {
      final pos = Fen.parse(
        'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3',
      );
      expect(San.format(pos, Move.fromUci('e5f6')), 'exf6');
    });

    test('10. Kingside castling (O-O)', () {
      final pos = Fen.parse(
        'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQK2R w KQkq - 1 6',
      );
      expect(San.format(pos, Move.fromUci('e1g1')), 'O-O');
    });

    test('11. Queenside castling (O-O-O)', () {
      final whitePos = Fen.parse('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      expect(San.format(whitePos, Move.fromUci('e1c1')), 'O-O-O');
      final blackPos = Fen.parse(
        'r3kbnr/pppqpppp/2np4/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1',
      );
      expect(San.format(blackPos, Move.fromUci('e8c8')), 'O-O-O');
    });

    test('12. Promotion without capture', () {
      final pos = Fen.parse('8/4P3/8/8/8/8/8/k6K w - - 0 1');
      expect(San.format(pos, Move.fromUci('e7e8q')), 'e8=Q');
      expect(San.format(pos, Move.fromUci('e7e8n')), 'e8=N');
    });

    test('13. Promotion with capture', () {
      final pos = Fen.parse('3r3k/4P3/8/8/8/8/8/7K w - - 0 1');
      expect(San.format(pos, Move.fromUci('e7d8q')), 'exd8=Q+');
    });

    test('14. Check (+)', () {
      final pos = Fen.parse(
        'rnbqkbnr/ppppp1pp/8/5p2/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      );
      expect(San.format(pos, Move.fromUci('d1h5')), 'Qh5+');
    });

    test('15. Checkmate (#) fools mate', () {
      final pos = Fen.parse(
        'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2',
      );
      expect(San.format(pos, Move.fromUci('d8h4')), 'Qh4#');
    });

    test('16. Disambiguation by file', () {
      // Hai xe trắng ở a1 và f1 đều đi được tới d1
      final pos = Fen.parse('r4rk1/8/8/8/8/8/8/R4R1K w - - 0 1');
      expect(San.format(pos, Move.fromUci('a1d1')), 'Rad1');
      expect(San.format(pos, Move.fromUci('f1d1')), 'Rfd1');
    });

    test('17. Disambiguation by rank', () {
      // Hai xe trắng ở d1 và d8 đều đi được tới d4
      final pos = Fen.parse('3R4/1k6/8/8/8/8/8/3R3K w - - 0 1');
      expect(San.format(pos, Move.fromUci('d1d4')), 'R1d4');
      expect(San.format(pos, Move.fromUci('d8d4')), 'R8d4');
    });

    test('18. Disambiguation by both file and rank', () {
      // Ba hậu ở d1, d8, a1 cùng đi tới d4
      final pos3 = Fen.parse('3Q4/1k6/8/8/8/8/8/Q2Q3K w - - 0 1');
      expect(San.format(pos3, Move.fromUci('d1d4')), 'Qd1d4');
    });
  });
}
