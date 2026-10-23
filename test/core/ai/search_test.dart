import 'package:chess/core/ai/search.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('T3.2 Search: Mate in 1 (≥ 5 positions)', () {
    test('1. Back-rank mate: Rd8#', () {
      final pos = Fen.parse('6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');
      final result = search([pos], const SearchConfig(maxDepth: 2));
      expect(result.bestMove.toUci(), 'd1d8');
      expect(result.scoreCp, greaterThan(90000));
    });

    test('2. Queen helper mate: Qg7# or Qf8#', () {
      final pos = Fen.parse('7k/5Q2/6K1/8/8/8/8/8 w - - 0 1');
      final result = search([pos], const SearchConfig(maxDepth: 2));
      expect(const {'f7g7', 'f7f8'}.contains(result.bestMove.toUci()), isTrue);
      expect(result.scoreCp, greaterThan(90000));
    });

    test('3. Scholars mate attack: Qxf7#', () {
      final pos = Fen.parse(
        'r1bqkb1r/pppp1ppp/2n5/4p3/2B1n3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 4',
      );
      final result = search([pos], const SearchConfig(maxDepth: 2));
      expect(result.bestMove.toUci(), 'f3f7');
      expect(result.scoreCp, greaterThan(90000));
    });

    test('4. Box mate with Rook: Rh8#', () {
      final pos = Fen.parse('k7/8/1K6/8/8/8/8/7R w - - 0 1');
      final result = search([pos], const SearchConfig(maxDepth: 2));
      expect(result.bestMove.toUci(), 'h1h8');
      expect(result.scoreCp, greaterThan(90000));
    });

    test('5. Fools mate: Qh4#', () {
      final pos = Fen.parse(
        'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2',
      );
      final result = search([pos], const SearchConfig(maxDepth: 2));
      expect(result.bestMove.toUci(), 'd8h4');
      expect(result.scoreCp, greaterThan(90000));
    });
  });

  group('T3.2 Search: Mate in 2 (≥ 3 positions with maxDepth: 4)', () {
    test('1. Queen backrank sacrifice/deflection mate in 2', () {
      // 1. Rxd8+ Rxd8 2. Rxd8# hoặc 1. Qd8+ Rxd8 2. Rxd8#
      final pos = Fen.parse('3r2k1/5ppp/8/8/8/8/3Q1PPP/3R2K1 w - - 0 1');
      final result = search([pos], const SearchConfig(maxDepth: 4));
      expect(const {'d2d8', 'd1d8'}.contains(result.bestMove.toUci()), isTrue);
      expect(result.scoreCp, greaterThan(90000));
    });

    test('2. Pure mate in 2: King and Rook endgame', () {
      // 8/8/8/8/8/5K2/4R3/7k w - - 0 1
      // Không có mate in 1: 1. Kg3! Kg1 2. Re1#
      final pos = Fen.parse('8/8/8/8/8/5K2/4R3/7k w - - 0 1');
      // Ở depth 2 không thể tìm ra mate vì mate ở ply 3
      final resultD2 = search([pos], const SearchConfig(maxDepth: 2));
      expect(resultD2.scoreCp, lessThan(90000));

      final result = search([pos], const SearchConfig(maxDepth: 4));
      expect(result.bestMove.toUci(), 'f3g3');
      expect(result.scoreCp, greaterThan(90000));
    });

    test('3. Back-rank corridor mate in 2', () {
      final pos = Fen.parse('r5k1/5ppp/8/8/8/8/4QPPP/R5K1 w - - 0 1');
      final result = search([pos], const SearchConfig(maxDepth: 4));
      // 1. Rxa8+ or 1. Qe8+
      expect(const {'a1a8', 'e2e8'}.contains(result.bestMove.toUci()), isTrue);
      expect(result.scoreCp, greaterThan(90000));
    });
  });

  group('T3.2 Search: Hanging pieces (≥ 3 positions)', () {
    test('1. Captures hanging rook: Qxd5', () {
      // Xe đen ở d5 hoàn toàn treo, không có quân bảo vệ
      final pos = Fen.parse('4k3/8/8/3r4/8/8/8/3Q2K1 w - - 0 1');
      final result = search([pos], const SearchConfig(maxDepth: 3));
      expect(result.bestMove.toUci(), 'd1d5');
    });

    test('2. Saves hanging queen attacked by pawn', () {
      final pos = Fen.parse(
        'rnb1kbnr/ppp1pppp/8/3p4/4Q3/8/PPPPPPPP/RNB1KBNR w KQkq - 0 1',
      );
      final result = search([pos], const SearchConfig(maxDepth: 3));
      // Queen must either capture d5 or flee safely (e4d5, e4e3, e4a4, etc.)
      expect(result.bestMove.toUci().startsWith('e4'), isTrue);
    });

    test('3. Captures hanging knight: Nxe5', () {
      // Mã đen ở e5 bị mã trắng f3 ăn
      final pos = Fen.parse(
        'rnbqkb1r/pppppppp/8/4n3/8/5N2/PPPPPPPP/RNBQKB1R w KQkq - 0 1',
      );
      final result = search([pos], const SearchConfig(maxDepth: 3));
      expect(result.bestMove.toUci(), 'f3e5');
    });
  });

  group('T3.2 Search: Robustness & Legality', () {
    test('Always returns legal move across 50 random positions', () {
      var currentPos = GamePosition.initial();
      final history = <GamePosition>[currentPos];

      for (var i = 0; i < 50; i++) {
        final legalMoves = <int>[];
        for (var sq = 0; sq < 64; sq++) {
          if (currentPos.board[sq].isNotEmpty &&
              ChessRules.isWhite(currentPos.board[sq]) ==
                  currentPos.whiteToMove) {
            legalMoves.addAll(ChessRules.legalMoves(currentPos, sq));
          }
        }

        if (ChessRules.status(currentPos).isGameOver || legalMoves.isEmpty) {
          currentPos = GamePosition.initial();
          history
            ..clear()
            ..add(currentPos);
          continue;
        }

        final result = search(
          history,
          SearchConfig(maxDepth: 2, seed: 1000 + i),
        );

        // Verify the returned move is legal
        final moveFrom = result.bestMove.from;
        final moveTo = result.bestMove.to;
        final movesForFrom = ChessRules.legalMoves(currentPos, moveFrom);
        expect(
          movesForFrom.contains(moveTo),
          isTrue,
          reason:
              'Move ${result.bestMove.toUci()} is not legal in position ${Fen.format(currentPos)}',
        );

        // Apply and continue
        final moveRes = ChessRules.applyMove(
          currentPos,
          moveFrom,
          moveTo,
          promotion: result.bestMove.promotion ?? 'q',
        );
        currentPos = moveRes.position;
        history.add(currentPos);
      }
    });

    test('Same seed produces identical result', () {
      final pos = GamePosition.initial();
      final r1 = search(
        [pos],
        const SearchConfig(
          maxDepth: 3,
          randomMarginCp: 50,
          blunderChance: 0.2,
          seed: 42,
        ),
      );
      final r2 = search(
        [pos],
        const SearchConfig(
          maxDepth: 3,
          randomMarginCp: 50,
          blunderChance: 0.2,
          seed: 42,
        ),
      );
      expect(r1.bestMove, equals(r2.bestMove));
      expect(r1.scoreCp, equals(r2.scoreCp));
    });

    test('timeLimit: 300ms completes within 400ms', () {
      final pos = GamePosition.initial();
      final sw = Stopwatch()..start();
      final result = search(
        [pos],
        const SearchConfig(
          maxDepth: 30,
          timeLimit: Duration(milliseconds: 300),
        ),
      );
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThanOrEqualTo(400));
      expect(result.depthReached, greaterThanOrEqualTo(1));
    }, tags: ['slow']);

    test('Draw conditions evaluated to scoreCp: 0', () {
      // 1. Halfmove clock >= 100 -> scoreCp: 0
      final halfmovePos = Fen.parse('8/8/8/8/8/5K2/8/k6N w - - 100 1');
      final resHalfmove = search([
        halfmovePos,
      ], const SearchConfig(maxDepth: 2));
      expect(resHalfmove.scoreCp, equals(0));

      // 2. Insufficient material: K+N vs K -> scoreCp: 0
      final knkPos = Fen.parse('8/8/8/8/8/5K2/8/k6N w - - 0 1');
      final resKnk = search([knkPos], const SearchConfig(maxDepth: 2));
      expect(resKnk.scoreCp, equals(0));

      // 3. Insufficient material: K+B vs K -> scoreCp: 0
      final kbkPos = Fen.parse('8/8/8/8/8/5K2/8/k6B w - - 0 1');
      final resKbk = search([kbkPos], const SearchConfig(maxDepth: 2));
      expect(resKbk.scoreCp, equals(0));

      // 4. Insufficient material: K vs K -> scoreCp: 0
      final kkPos = Fen.parse('8/8/8/8/8/5K2/8/k7 w - - 0 1');
      final resKk = search([kkPos], const SearchConfig(maxDepth: 2));
      expect(resKk.scoreCp, equals(0));
    });
  });
}
