import 'package:chess/core/ai/search_board.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:flutter_test/flutter_test.dart';

int perft(
  SearchBoard board,
  int depth, {
  bool verifyZobrist = false,
  bool verifyCaptures = false,
}) {
  if (depth == 0) return 1;

  final moves = <int>[];
  board.generateLegalMoves(moves);

  if (verifyCaptures) {
    final captures = <int>[];
    board.generateCaptures(captures);
    final legalSet = moves.toSet();
    for (final c in captures) {
      expect(
        legalSet.contains(c),
        isTrue,
        reason: 'Capture $c not in legal moves',
      );
    }
  }

  if (depth == 1 && !verifyZobrist) return moves.length;

  var nodes = 0;
  for (var i = 0; i < moves.length; i++) {
    final m = moves[i];
    final beforeKey = board.zobristKey;
    final beforeBoard = List<int>.from(board.board);

    board.makeMove(m);

    if (verifyZobrist) {
      expect(
        board.zobristKey,
        board.computeZobristKey(),
        reason: 'Zobrist key mismatch after move',
      );
    }

    nodes += perft(
      board,
      depth - 1,
      verifyZobrist: verifyZobrist,
      verifyCaptures: verifyCaptures,
    );

    board.unmakeMove();

    if (verifyZobrist) {
      expect(board.zobristKey, beforeKey, reason: 'Zobrist key after unmake');
      expect(board.board, beforeBoard, reason: 'Board after unmake');
    }
  }
  return nodes;
}

void main() {
  group('SearchBoard Perft verification', () {
    test('Initial position depth 4 = 197281', () {
      final board = SearchBoard.fromPosition(GamePosition.initial());
      expect(perft(board, 4), 197281);
    });

    test('Kiwipete depth 3 = 97862 with Zobrist & capture verification', () {
      final pos = Fen.parse(
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
      );
      final board = SearchBoard.fromPosition(pos);
      expect(perft(board, 3, verifyZobrist: true, verifyCaptures: true), 97862);
    });

    test('Position 3 depth 5 = 674624', () {
      final pos = Fen.parse('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1');
      final board = SearchBoard.fromPosition(pos);
      expect(perft(board, 5), 674624);
    });
  });

  group('SearchBoard Move conversion (toMove / fromMove)', () {
    test('roundtrip legal moves', () {
      final board = SearchBoard.fromPosition(GamePosition.initial());
      final legal = <int>[];
      board.generateLegalMoves(legal);

      for (final encoded in legal) {
        final engineMove = board.toMove(encoded);
        final back = board.fromMove(engineMove);
        expect(back, encoded);
      }
    });

    test('fromMove throws ArgumentError on illegal move', () {
      final board = SearchBoard.fromPosition(GamePosition.initial());
      expect(
        () => board.fromMove(const Move(52, 28)), // e2 -> e5 (illegal)
        throwsArgumentError,
      );
    });
  });
}
