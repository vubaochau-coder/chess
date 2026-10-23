import 'package:chess/core/ai/search_board.dart';

abstract final class Evaluation {
  static const int pawnVal = 100;
  static const int knightVal = 320;
  static const int bishopVal = 330;
  static const int rookVal = 500;
  static const int queenVal = 900;

  // Bảng điểm vị trí (Tomasz Michniewski - Simplified Evaluation Function)
  // Index theo quy ước repo: hàng 0 = rank 8, hàng 7 = rank 1.
  static const List<int> pawnTable = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    50,
    50,
    50,
    50,
    50,
    50,
    50,
    50,
    10,
    10,
    20,
    30,
    30,
    20,
    10,
    10,
    5,
    5,
    10,
    25,
    25,
    10,
    5,
    5,
    0,
    0,
    0,
    20,
    20,
    0,
    0,
    0,
    5,
    -5,
    -10,
    0,
    0,
    -10,
    -5,
    5,
    5,
    10,
    10,
    -20,
    -20,
    10,
    10,
    5,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  static const List<int> knightTable = [
    -50,
    -40,
    -30,
    -30,
    -30,
    -30,
    -40,
    -50,
    -40,
    -20,
    0,
    0,
    0,
    0,
    -20,
    -40,
    -30,
    0,
    10,
    15,
    15,
    10,
    0,
    -30,
    -30,
    5,
    15,
    20,
    20,
    15,
    5,
    -30,
    -30,
    0,
    15,
    20,
    20,
    15,
    0,
    -30,
    -30,
    5,
    10,
    15,
    15,
    10,
    5,
    -30,
    -40,
    -20,
    0,
    5,
    5,
    0,
    -20,
    -40,
    -50,
    -40,
    -30,
    -30,
    -30,
    -30,
    -40,
    -50,
  ];

  static const List<int> bishopTable = [
    -20,
    -10,
    -10,
    -10,
    -10,
    -10,
    -10,
    -20,
    -10,
    0,
    0,
    0,
    0,
    0,
    0,
    -10,
    -10,
    0,
    5,
    10,
    10,
    5,
    0,
    -10,
    -10,
    5,
    5,
    10,
    10,
    5,
    5,
    -10,
    -10,
    0,
    10,
    10,
    10,
    10,
    0,
    -10,
    -10,
    10,
    10,
    10,
    10,
    10,
    10,
    -10,
    -10,
    5,
    0,
    0,
    0,
    0,
    5,
    -10,
    -20,
    -10,
    -10,
    -10,
    -10,
    -10,
    -10,
    -20,
  ];

  static const List<int> rookTable = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    5,
    10,
    10,
    10,
    10,
    10,
    10,
    5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    0,
    0,
    0,
    5,
    5,
    0,
    0,
    0,
  ];

  static const List<int> queenTable = [
    -20,
    -10,
    -10,
    -5,
    -5,
    -10,
    -10,
    -20,
    -10,
    0,
    0,
    0,
    0,
    0,
    0,
    -10,
    -10,
    0,
    5,
    5,
    5,
    5,
    0,
    -10,
    -5,
    0,
    5,
    5,
    5,
    5,
    0,
    -5,
    0,
    0,
    5,
    5,
    5,
    5,
    0,
    -5,
    -10,
    5,
    5,
    5,
    5,
    5,
    0,
    -10,
    -10,
    0,
    5,
    0,
    0,
    0,
    0,
    -10,
    -20,
    -10,
    -10,
    -5,
    -5,
    -10,
    -10,
    -20,
  ];

  static const List<int> kingMiddleTable = [
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -20,
    -30,
    -30,
    -40,
    -40,
    -30,
    -30,
    -20,
    -10,
    -20,
    -20,
    -20,
    -20,
    -20,
    -20,
    -10,
    20,
    20,
    0,
    0,
    0,
    0,
    20,
    20,
    20,
    30,
    10,
    0,
    0,
    10,
    30,
    20,
  ];

  static const List<int> kingEndTable = [
    -50,
    -40,
    -30,
    -20,
    -20,
    -30,
    -40,
    -50,
    -30,
    -20,
    -10,
    0,
    0,
    -10,
    -20,
    -30,
    -30,
    -10,
    20,
    30,
    30,
    20,
    -10,
    -30,
    -30,
    -10,
    30,
    40,
    40,
    30,
    -10,
    -30,
    -30,
    -10,
    30,
    40,
    40,
    30,
    -10,
    -30,
    -30,
    -10,
    20,
    30,
    30,
    20,
    -10,
    -30,
    -30,
    -30,
    0,
    0,
    0,
    0,
    -30,
    -30,
    -50,
    -30,
    -30,
    -30,
    -30,
    -30,
    -30,
    -50,
  ];

  static int evaluate(SearchBoard board) {
    final b = board.board;
    var whiteMaterial = 0;
    var blackMaterial = 0;

    var whitePst = 0;
    var blackPst = 0;

    var whiteQueens = 0;
    var blackQueens = 0;
    var whiteMinors = 0;
    var blackMinors = 0;

    var whiteKingSq = 0;
    var blackKingSq = 0;

    for (var sq = 0; sq < 64; sq++) {
      final p = b[sq];
      if (p == 0) continue;

      final isWhite = (p & 8) == 0;
      final type = p & 7;

      if (isWhite) {
        switch (type) {
          case 1:
            whiteMaterial += pawnVal;
            whitePst += pawnTable[sq];
          case 2:
            whiteMaterial += knightVal;
            whiteMinors++;
            whitePst += knightTable[sq];
          case 3:
            whiteMaterial += bishopVal;
            whiteMinors++;
            whitePst += bishopTable[sq];
          case 4:
            whiteMaterial += rookVal;
            whitePst += rookTable[sq];
          case 5:
            whiteMaterial += queenVal;
            whiteQueens++;
            whitePst += queenTable[sq];
          case 6:
            whiteKingSq = sq;
        }
      } else {
        final flipSq = sq ^ 56;
        switch (type) {
          case 1:
            blackMaterial += pawnVal;
            blackPst += pawnTable[flipSq];
          case 2:
            blackMaterial += knightVal;
            blackMinors++;
            blackPst += knightTable[flipSq];
          case 3:
            blackMaterial += bishopVal;
            blackMinors++;
            blackPst += bishopTable[flipSq];
          case 4:
            blackMaterial += rookVal;
            blackPst += rookTable[flipSq];
          case 5:
            blackMaterial += queenVal;
            blackQueens++;
            blackPst += queenTable[flipSq];
          case 6:
            blackKingSq = sq;
        }
      }
    }

    // Đánh giá tàn cuộc cho Vua:
    // Cả 2 bên không còn hậu, HOẶC bên còn hậu chỉ còn tối đa 1 quân nhẹ
    final isEndgame =
        (whiteQueens == 0 && blackQueens == 0) ||
        ((whiteQueens == 0 || (whiteQueens == 1 && whiteMinors <= 1)) &&
            (blackQueens == 0 || (blackQueens == 1 && blackMinors <= 1)));

    if (isEndgame) {
      whitePst += kingEndTable[whiteKingSq];
      blackPst += kingEndTable[blackKingSq ^ 56];
    } else {
      whitePst += kingMiddleTable[whiteKingSq];
      blackPst += kingMiddleTable[blackKingSq ^ 56];
    }

    final totalScore = (whiteMaterial + whitePst) - (blackMaterial + blackPst);
    return board.whiteToMove ? totalScore : -totalScore;
  }
}
