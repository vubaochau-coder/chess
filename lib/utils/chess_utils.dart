import 'package:chess/models/abstract/chess_model.dart';
import 'package:chess/models/chess/black_bishop_model.dart';
import 'package:chess/models/chess/black_knight_model.dart';
import 'package:chess/models/chess/black_king_model.dart';
import 'package:chess/models/chess/black_pawn_model.dart';
import 'package:chess/models/chess/black_queen_model.dart';
import 'package:chess/models/chess/black_rook_model.dart';
import 'package:chess/models/chess/white_bishop_model.dart';
import 'package:chess/models/chess/white_king_model.dart';
import 'package:chess/models/chess/white_knight_model.dart';
import 'package:chess/models/chess/white_pawn_model.dart';
import 'package:chess/models/chess/white_queen_model.dart';
import 'package:chess/models/chess/white_rook_model.dart';
import 'package:chess/models/position_model.dart';

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

  static Chess? strToChess(String chess, Position p) {
    switch (chess) {
      case 'K':
        return WhiteKingModel(p);
      case 'Q':
        return WhiteQueenModel(p);
      case 'R':
        return WhiteRookModel(p);
      case 'B':
        return WhiteBishopModel(p);
      case 'N':
        return WhiteKnightModel(p);
      case 'P':
        return WhitePawnModel(p);
      case 'k':
        return BlackKingModel(p);
      case 'q':
        return BlackQueenModel(p);
      case 'r':
        return BlackRookModel(p);
      case 'b':
        return BlackBishopModel(p);
      case 'n':
        return BlackKnightModel(p);
      case 'p':
        return BlackPawnModel(p);
      default:
        return null;
    }
  }

  static bool isWhitePawnInit(Position p) {
    return p.x == 6;
  }

  static bool isBlackPawnInit(Position p) {
    return p.x == 1;
  }

  static List<String> readGameState(String state) {
    List<String> chess = [];
    final rows = state.split('/');
    for (var row in rows) {
      final items = row.split('');
      if (items.length == 8) {
        chess.addAll(items);
      } else {
        for (var item in items) {
          if (ChessUtils.chessStr.contains(item)) {
            chess.add(item);
          } else {
            int? value = int.tryParse(item);
            if (value != null) {
              final empty = List<String>.generate(value, (index) => '');
              chess.addAll(empty);
            } else {
              throw Exception('Format Chess Not Correct');
            }
          }
        }
      }
    }

    return chess;
  }

  static String saveGameState(List<String> state) {
    List<String> mergeGameState = [];

    for (int i = 0; i < 64; i += 8) {
      List<String> mergeRow = [];
      int countEmpty = 0;

      for (int j = 0; j < 8; j++) {
        String cell = state[i + j];
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
