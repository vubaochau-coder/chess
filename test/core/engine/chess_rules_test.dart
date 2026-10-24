import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:flutter_test/flutter_test.dart';

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
    final pos = GamePosition.initial();
    expect(perft(pos, 1), 20);
    expect(perft(pos, 2), 400);
    expect(perft(pos, 3), 8902);
  });

  test('perft kiwipete (castling, en passant, pins)', () {
    final pos = Fen.parse(
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -',
    );
    expect(perft(pos, 1), 48);
    expect(perft(pos, 2), 2039);
    expect(perft(pos, 3), 97862);
  });

  test('perft endgame with en passant discovered checks', () {
    final pos = Fen.parse('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -');
    expect(perft(pos, 1), 14);
    expect(perft(pos, 2), 191);
    expect(perft(pos, 3), 2812);
    expect(perft(pos, 4), 43238);
  });

  test("fool's mate is checkmate", () {
    var pos = GamePosition.initial();
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
    final pos = Fen.parse('7k/5Q2/6K1/8/8/8/8/8 b - -');
    expect(ChessRules.status(pos), GameStatus.stalemate);
  });

  test('castling moves the rook and pawn promotes to queen', () {
    final castle = ChessRules.applyMove(
      Fen.parse('r3k2r/8/8/8/8/8/8/R3K2R w KQkq -'),
      60,
      62,
    );
    expect(castle.isCastle, isTrue);
    expect(castle.position.board[61], 'R');
    expect(castle.position.castling, 'kq');

    final promote = ChessRules.applyMove(
      Fen.parse('8/P6k/8/8/8/8/8/K7 w - -'),
      8,
      0,
    );
    expect(promote.isPromotion, isTrue);
    expect(promote.position.board[0], 'Q');
  });

  group('positionRepetitionKey', () {
    test('same key when en passant cannot be captured vs no en passant', () {
      final posWithEp = Fen.parse(
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      );
      final posWithoutEp = Fen.parse(
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
      );

      final keyWithEp = ChessRules.positionRepetitionKey(posWithEp);
      final keyWithoutEp = ChessRules.positionRepetitionKey(posWithoutEp);

      expect(keyWithEp, equals(keyWithoutEp));
    });

    test('different keys when en passant can be captured vs no en passant', () {
      // Black pawn at d4 can capture white pawn at e4 via e3
      final posCanCapture = Fen.parse(
        'rnbqkbnr/ppp1pppp/8/8/3pP3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      );
      final posNoEp = Fen.parse(
        'rnbqkbnr/ppp1pppp/8/8/3pP3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
      );

      final keyCanCapture = ChessRules.positionRepetitionKey(posCanCapture);
      final keyNoEp = ChessRules.positionRepetitionKey(posNoEp);

      expect(keyCanCapture, isNot(equals(keyNoEp)));
    });
  });

  group('isLegalMove', () {
    test('validates legal and illegal moves correctly', () {
      final initial = GamePosition.initial();

      // Nước hợp lệ
      expect(ChessRules.isLegalMove(initial, Move.fromUci('e2e4')), isTrue);
      expect(ChessRules.isLegalMove(initial, Move.fromUci('g1f3')), isTrue);

      // Nước không hợp lệ: sai vị trí đích (tốt nhảy 3 ô)
      expect(ChessRules.isLegalMove(initial, Move.fromUci('e2e5')), isFalse);

      // Nước không hợp lệ: đi xuyên quân (xe a1 đi qua a2)
      expect(ChessRules.isLegalMove(initial, Move.fromUci('a1a3')), isFalse);

      // Nước không hợp lệ: tự đưa vào thế chiếu
      final pinPos = Fen.parse('4k3/8/8/4r3/8/8/4K3/8 w - - 0 1');
      // Vua trắng bị chiếu bởi xe e5, đi tốt hay nước không đỡ chiếu là sai
      expect(
        ChessRules.isLegalMove(
          pinPos,
          Move.fromUci('e2e3'),
        ), // Vua vẫn trên cột e
        isFalse,
      );

      // Nước phong cấp thiếu quân phong cấp (e7e8 nhưng không có promotion)
      final promoPos = Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1');
      // sq 8 là a7, sq 0 là a8
      expect(ChessRules.isLegalMove(promoPos, const Move(8, 0)), isFalse);

      // Nước thường kèm quân phong cấp (e2e4 kèm 'q')
      expect(
        ChessRules.isLegalMove(initial, const Move(52, 36, promotion: 'q')),
        isFalse,
      );

      // Nước phong cấp hợp lệ (a7a8q)
      expect(
        ChessRules.isLegalMove(promoPos, const Move(8, 0, promotion: 'q')),
        isTrue,
      );
    });

    test('GameStatus resignation properties', () {
      expect(GameStatus.whiteResigned.isGameOver, isTrue);
      expect(GameStatus.whiteResigned.isDraw, isFalse);
      expect(GameStatus.blackResigned.isGameOver, isTrue);
      expect(GameStatus.blackResigned.isDraw, isFalse);
    });
  });
}
