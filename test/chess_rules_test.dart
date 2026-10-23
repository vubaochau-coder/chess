import 'package:chess/utils/chess_rules.dart';
import 'package:chess/utils/chess_utils.dart';
import 'package:flutter_test/flutter_test.dart';

GamePosition fromFen(String fen) {
  final parts = fen.split(' ');
  int? enPassant;
  if (parts[3] != '-') {
    final col = parts[3].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(parts[3][1]);
    enPassant = row * 8 + col;
  }
  return GamePosition(
    board: ChessUtils.readGameState(parts[0]),
    whiteToMove: parts[1] == 'w',
    castling: parts[2] == '-' ? '' : parts[2],
    enPassant: enPassant,
  );
}

// Đếm số thế cờ ở độ sâu [depth], so với giá trị chuẩn để kiểm tra luật đi
int perft(GamePosition pos, int depth) {
  if (depth == 0) return 1;
  var count = 0;
  for (var from = 0; from < 64; from++) {
    for (final to in ChessRules.legalMoves(pos, from)) {
      count += perft(ChessRules.applyMove(pos, from, to).position, depth - 1);
    }
  }
  return count;
}

void main() {
  test('perft from the initial position', () {
    final pos = GamePosition(
      board: ChessUtils.readGameState(ChessUtils.initGame),
    );
    expect(perft(pos, 1), 20);
    expect(perft(pos, 2), 400);
    expect(perft(pos, 3), 8902);
  });

  test('perft kiwipete (castling, en passant, pins)', () {
    final pos = fromFen(
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -',
    );
    expect(perft(pos, 1), 48);
    expect(perft(pos, 2), 2039);
    expect(perft(pos, 3), 97862);
  });

  test('perft endgame with en passant discovered checks', () {
    final pos = fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -');
    expect(perft(pos, 1), 14);
    expect(perft(pos, 2), 191);
    expect(perft(pos, 3), 2812);
    expect(perft(pos, 4), 43238);
  });

  test("fool's mate is checkmate", () {
    var pos = GamePosition(
      board: ChessUtils.readGameState(ChessUtils.initGame),
    );
    // f3, e5, g4, Qh4#
    for (final move in [
      [53, 45],
      [12, 28],
      [54, 38],
      [3, 39],
    ]) {
      pos = ChessRules.applyMove(pos, move[0], move[1]).position;
    }
    expect(ChessRules.status(pos), GameStatus.checkmate);
  });

  test('stalemate is detected', () {
    final pos = fromFen('7k/5Q2/6K1/8/8/8/8/8 b - -');
    expect(ChessRules.status(pos), GameStatus.stalemate);
  });

  test('castling moves the rook and pawn promotes to queen', () {
    final castle = ChessRules.applyMove(
      fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq -'),
      60,
      62,
    );
    expect(castle.isCastle, isTrue);
    expect(castle.position.board[61], 'R');
    expect(castle.position.castling, 'kq');

    final promote = ChessRules.applyMove(
      fromFen('8/P6k/8/8/8/8/8/K7 w - -'),
      8,
      0,
    );
    expect(promote.isPromotion, isTrue);
    expect(promote.position.board[0], 'Q');
  });
}
