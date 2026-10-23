/*
Luật cờ vua thuần Dart (không phụ thuộc Flutter).

Bàn cờ là List<String> 64 ô, index = x * 8 + y:
  x = hàng (0 = hàng 8 phía quân đen, 7 = hàng 1 phía quân trắng)
  y = cột  (0 = cột a, 7 = cột h)
Chữ hoa là quân trắng, chữ thường là quân đen, '' là ô trống.
*/

import 'package:chess/core/engine/fen.dart';

enum GameStatus { playing, check, checkmate, stalemate }

class GamePosition {
  final List<String> board;
  final bool whiteToMove;

  // Quyền nhập thành theo kiểu FEN: 'K', 'Q', 'k', 'q'
  final String castling;

  // Ô có thể bắt tốt qua đường (nếu có)
  final int? enPassant;

  final int halfmoveClock;
  final int fullmoveNumber;

  const GamePosition({
    required this.board,
    this.whiteToMove = true,
    this.castling = 'KQkq',
    this.enPassant,
    this.halfmoveClock = 0,
    this.fullmoveNumber = 1,
  });

  /// Thế cờ bắt đầu ván.
  factory GamePosition.initial() {
    return Fen.parse(Fen.initial);
  }
}

class MoveResult {
  final GamePosition position;
  final bool isCapture;
  final bool isCastle;
  final bool isPromotion;

  const MoveResult({
    required this.position,
    this.isCapture = false,
    this.isCastle = false,
    this.isPromotion = false,
  });
}

class ChessRules {
  static const _knightSteps = [
    [2, 1],
    [2, -1],
    [-2, 1],
    [-2, -1],
    [1, 2],
    [1, -2],
    [-1, 2],
    [-1, -2],
  ];
  static const _kingSteps = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];
  static const _rookDirs = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];
  static const _bishopDirs = [
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  static bool isWhite(String piece) =>
      piece.isNotEmpty && piece == piece.toUpperCase();

  static bool _onBoard(int x, int y) => x >= 0 && x < 8 && y >= 0 && y < 8;

  static bool _isEnemy(String a, String b) =>
      a.isNotEmpty && b.isNotEmpty && isWhite(a) != isWhite(b);

  /// Các nước đi của quân tại [from] theo cách di chuyển, chưa xét việc
  /// vua có bị chiếu sau khi đi hay không. Không bao gồm nhập thành.
  static List<int> pseudoMoves(List<String> board, int from, {int? enPassant}) {
    final piece = board[from];
    if (piece.isEmpty) return [];

    final x = from ~/ 8;
    final y = from % 8;
    final moves = <int>[];

    void addSteps(List<List<int>> steps) {
      for (final s in steps) {
        final nx = x + s[0], ny = y + s[1];
        if (!_onBoard(nx, ny)) continue;
        final target = board[nx * 8 + ny];
        if (target.isEmpty || _isEnemy(piece, target)) moves.add(nx * 8 + ny);
      }
    }

    void addSlides(List<List<int>> dirs) {
      for (final d in dirs) {
        var nx = x + d[0], ny = y + d[1];
        while (_onBoard(nx, ny)) {
          final target = board[nx * 8 + ny];
          if (target.isEmpty) {
            moves.add(nx * 8 + ny);
          } else {
            if (_isEnemy(piece, target)) moves.add(nx * 8 + ny);
            break;
          }
          nx += d[0];
          ny += d[1];
        }
      }
    }

    switch (piece.toLowerCase()) {
      case 'n':
        addSteps(_knightSteps);
      case 'k':
        addSteps(_kingSteps);
      case 'r':
        addSlides(_rookDirs);
      case 'b':
        addSlides(_bishopDirs);
      case 'q':
        addSlides(_rookDirs);
        addSlides(_bishopDirs);
      case 'p':
        final dir = isWhite(piece) ? -1 : 1;
        final startRow = isWhite(piece) ? 6 : 1;
        final nx = x + dir;
        if (!_onBoard(nx, y)) break;

        if (board[nx * 8 + y].isEmpty) {
          moves.add(nx * 8 + y);
          if (x == startRow && board[(nx + dir) * 8 + y].isEmpty) {
            moves.add((nx + dir) * 8 + y);
          }
        }
        for (final dy in [-1, 1]) {
          final ny = y + dy;
          if (!_onBoard(nx, ny)) continue;
          final target = nx * 8 + ny;
          if (_isEnemy(piece, board[target]) || target == enPassant) {
            moves.add(target);
          }
        }
    }

    return moves;
  }

  /// Ô [square] có đang bị phe [byWhite] tấn công không.
  static bool isSquareAttacked(List<String> board, int square, bool byWhite) {
    final x = square ~/ 8;
    final y = square % 8;

    String at(int nx, int ny) => board[nx * 8 + ny];
    bool isAttacker(String p, String type) =>
        p.isNotEmpty && isWhite(p) == byWhite && p.toLowerCase() == type;

    // Tốt trắng tấn công lên trên (x - 1), nên tốt tấn công ô này nằm ở x + 1
    final pawnRow = byWhite ? x + 1 : x - 1;
    for (final dy in [-1, 1]) {
      if (_onBoard(pawnRow, y + dy) && isAttacker(at(pawnRow, y + dy), 'p')) {
        return true;
      }
    }

    for (final s in _knightSteps) {
      final nx = x + s[0], ny = y + s[1];
      if (_onBoard(nx, ny) && isAttacker(at(nx, ny), 'n')) return true;
    }

    for (final s in _kingSteps) {
      final nx = x + s[0], ny = y + s[1];
      if (_onBoard(nx, ny) && isAttacker(at(nx, ny), 'k')) return true;
    }

    bool slideHits(List<List<int>> dirs, String type) {
      for (final d in dirs) {
        var nx = x + d[0], ny = y + d[1];
        while (_onBoard(nx, ny)) {
          final p = at(nx, ny);
          if (p.isNotEmpty) {
            if (isAttacker(p, type) || isAttacker(p, 'q')) return true;
            break;
          }
          nx += d[0];
          ny += d[1];
        }
      }
      return false;
    }

    return slideHits(_rookDirs, 'r') || slideHits(_bishopDirs, 'b');
  }

  static bool isInCheck(List<String> board, bool white) {
    final king = board.indexOf(white ? 'K' : 'k');
    if (king == -1) return false;
    return isSquareAttacked(board, king, !white);
  }

  /// Các nước đi hợp lệ của quân tại [from], gồm cả nhập thành.
  static List<int> legalMoves(GamePosition pos, int from) {
    final piece = pos.board[from];
    if (piece.isEmpty || isWhite(piece) != pos.whiteToMove) return [];

    final candidates = pseudoMoves(pos.board, from, enPassant: pos.enPassant)
      ..addAll(_castlingMoves(pos, from));

    return candidates.where((to) {
      final next = _movePieces(pos.board, from, to, pos.enPassant);
      return !isInCheck(next, pos.whiteToMove);
    }).toList();
  }

  static List<int> _castlingMoves(GamePosition pos, int from) {
    final piece = pos.board[from];
    final white = isWhite(piece);
    final home = white ? 60 : 4; // e1 / e8
    if (piece.toLowerCase() != 'k' || from != home) return [];
    if (isInCheck(pos.board, white)) return [];

    final moves = <int>[];
    final enemy = !white;
    bool empty(int i) => pos.board[i].isEmpty;
    bool safe(int i) => !isSquareAttacked(pos.board, i, enemy);

    if (pos.castling.contains(white ? 'K' : 'k') &&
        pos.board[home + 3] == (white ? 'R' : 'r') &&
        empty(home + 1) &&
        empty(home + 2) &&
        safe(home + 1)) {
      moves.add(home + 2);
    }
    if (pos.castling.contains(white ? 'Q' : 'q') &&
        pos.board[home - 4] == (white ? 'R' : 'r') &&
        empty(home - 1) &&
        empty(home - 2) &&
        empty(home - 3) &&
        safe(home - 1)) {
      moves.add(home - 2);
    }
    return moves;
  }

  /// Di chuyển quân trên bàn cờ (kèm xử lý bắt tốt qua đường, nhập thành,
  /// phong cấp), không kiểm tra tính hợp lệ.
  static List<String> _movePieces(
    List<String> board,
    int from,
    int to,
    int? enPassant, {
    String promotion = 'q',
  }) {
    final next = List<String>.from(board);
    final piece = next[from];
    final type = piece.toLowerCase();

    if (type == 'p' && to == enPassant && next[to].isEmpty) {
      // Quân tốt bị bắt nằm cùng hàng với quân tốt đi
      next[(from ~/ 8) * 8 + to % 8] = '';
    }

    if (type == 'k' && (to - from).abs() == 2) {
      final kingSide = to > from;
      final rookFrom = kingSide ? from + 3 : from - 4;
      final rookTo = kingSide ? from + 1 : from - 1;
      next[rookTo] = next[rookFrom];
      next[rookFrom] = '';
    }

    next[to] = piece;
    next[from] = '';

    final lastRow = to ~/ 8 == 0 || to ~/ 8 == 7;
    if (type == 'p' && lastRow) {
      next[to] = isWhite(piece) ? promotion.toUpperCase() : promotion;
    }

    return next;
  }

  /// Thực hiện nước đi (giả định đã hợp lệ) và trả về thế cờ mới.
  static MoveResult applyMove(
    GamePosition pos,
    int from,
    int to, {
    String promotion = 'q',
  }) {
    final piece = pos.board[from];
    final type = piece.toLowerCase();
    final isEnPassant = type == 'p' && to == pos.enPassant;
    final isCapture = pos.board[to].isNotEmpty || isEnPassant;
    final isCastle = type == 'k' && (to - from).abs() == 2;
    final isPromotion = type == 'p' && (to ~/ 8 == 0 || to ~/ 8 == 7);

    final board = _movePieces(
      pos.board,
      from,
      to,
      pos.enPassant,
      promotion: promotion,
    );

    var castling = pos.castling;
    if (piece == 'K') castling = castling.replaceAll(RegExp('[KQ]'), '');
    if (piece == 'k') castling = castling.replaceAll(RegExp('[kq]'), '');
    // Xe rời vị trí hoặc bị ăn thì mất quyền nhập thành bên đó
    for (final sq in [from, to]) {
      if (sq == 63) castling = castling.replaceAll('K', '');
      if (sq == 56) castling = castling.replaceAll('Q', '');
      if (sq == 7) castling = castling.replaceAll('k', '');
      if (sq == 0) castling = castling.replaceAll('q', '');
    }

    final enPassant = type == 'p' && (to - from).abs() == 16
        ? (from + to) ~/ 2
        : null;

    final isPawnMove = type == 'p';
    final halfmoveClock = (isPawnMove || isCapture) ? 0 : pos.halfmoveClock + 1;
    final fullmoveNumber = pos.whiteToMove
        ? pos.fullmoveNumber
        : pos.fullmoveNumber + 1;

    return MoveResult(
      position: GamePosition(
        board: board,
        whiteToMove: !pos.whiteToMove,
        castling: castling,
        enPassant: enPassant,
        halfmoveClock: halfmoveClock,
        fullmoveNumber: fullmoveNumber,
      ),
      isCapture: isCapture,
      isCastle: isCastle,
      isPromotion: isPromotion,
    );
  }

  static bool hasAnyLegalMove(GamePosition pos) {
    for (var i = 0; i < 64; i++) {
      final piece = pos.board[i];
      if (piece.isEmpty || isWhite(piece) != pos.whiteToMove) continue;
      if (legalMoves(pos, i).isNotEmpty) return true;
    }
    return false;
  }

  static GameStatus status(GamePosition pos) {
    final inCheck = isInCheck(pos.board, pos.whiteToMove);
    if (hasAnyLegalMove(pos)) {
      return inCheck ? GameStatus.check : GameStatus.playing;
    }
    return inCheck ? GameStatus.checkmate : GameStatus.stalemate;
  }
}
