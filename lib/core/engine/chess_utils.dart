import 'package:chess/core/engine/position_model.dart';

/*
White
K: King
Q: Queen
R: Rook
B: Bishop
N: Knight
P: Pawn

Black
k: King
q: Queen
r: Rook
b: Bishop
n: Knight
p: Pawn
*/

class ChessUtils {
  static String initGame = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR';

  static List<String> chessStr = [
    'K',
    'Q',
    'R',
    'B',
    'N',
    'P',
    'k',
    'q',
    'r',
    'b',
    'n',
    'p',
  ];

  static bool isWhitePawnInit(Position p) {
    return p.x == 6;
  }

  static bool isBlackPawnInit(Position p) {
    return p.x == 1;
  }

  static List<String> readGameState(String state) {
    final List<String> chess = [];
    final rows = state.split('/');
    for (final row in rows) {
      final items = row.split('');
      for (final item in items) {
        if (ChessUtils.chessStr.contains(item)) {
          chess.add(item);
        } else {
          final int? value = int.tryParse(item);
          if (value != null) {
            final empty = List<String>.generate(value, (index) => '');
            chess.addAll(empty);
          } else {
            throw Exception('Format Chess Not Correct');
          }
        }
      }
    }

    return chess;
  }

  static String saveGameState(List<String> state) {
    final List<String> mergeGameState = [];

    for (int i = 0; i < 64; i += 8) {
      final List<String> mergeRow = [];
      int countEmpty = 0;

      for (int j = 0; j < 8; j++) {
        final String cell = state[i + j];
        if (cell.isEmpty) {
          countEmpty++;
        } else {
          if (countEmpty > 0) {
            mergeRow.add(countEmpty.toString());
            countEmpty = 0;
          }
          mergeRow.add(cell);
        }
      }

      if (countEmpty > 0) {
        mergeRow.add(countEmpty.toString());
      }

      mergeGameState.add(mergeRow.join(''));
    }

    return mergeGameState.join('/');
  }
}
