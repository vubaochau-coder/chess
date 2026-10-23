import 'dart:math';
import 'dart:typed_data';

import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/move.dart';

class _Zobrist {
  static final List<List<int>> piece = List.generate(
    64,
    (_) => List.filled(16, 0),
  );
  static int sideToMove = 0;
  static final List<int> castling = List.filled(16, 0);
  static final List<int> enPassant = List.filled(8, 0);

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    final rng = Random(20261023);
    int rand64() {
      final hi = rng.nextInt(1 << 32);
      final lo = rng.nextInt(1 << 32);
      return (hi << 32) | lo;
    }

    for (var sq = 0; sq < 64; sq++) {
      for (var p = 0; p < 16; p++) {
        piece[sq][p] = rand64();
      }
    }
    sideToMove = rand64();
    for (var i = 0; i < 16; i++) {
      castling[i] = rand64();
    }
    for (var i = 0; i < 8; i++) {
      enPassant[i] = rand64();
    }
    _initialized = true;
  }
}

class _UndoState {
  int move = 0;
  int capturedPiece = 0;
  int castlingRights = 0;
  int enPassantCol = -1;
  int halfmoveClock = 0;
  int zobristKey = 0;
}

final class SearchBoard {
  SearchBoard._() {
    _Zobrist.ensureInitialized();
  }

  factory SearchBoard.fromPosition(GamePosition position) {
    final sb = SearchBoard._();
    sb._loadPosition(position);
    return sb;
  }

  static const int flagCapture = 1 << 15;
  static const int flagEnPassant = 1 << 16;
  static const int flagCastle = 1 << 17;
  static const int flagPawnTwo = 1 << 18;

  final Int8List _board = Int8List(64);
  bool _whiteToMove = true;
  int _castlingRights = 0; // bit 0: K, bit 1: Q, bit 2: k, bit 3: q
  int _enPassantCol = -1; // 0..7 hoặc -1 nếu không có
  int _halfmoveClock = 0;
  int _zobristKey = 0;

  int _whiteKingSq = -1;
  int _blackKingSq = -1;

  final List<_UndoState> _history = List.generate(512, (_) => _UndoState());
  int _ply = 0;

  // Buffer tạm để sinh nước đi tránh cấp phát bộ nhớ
  final List<List<int>> _moveBuffers = List.generate(64, (_) => <int>[]);

  bool get whiteToMove => _whiteToMove;
  int get zobristKey => _zobristKey;
  int get halfmoveClock => _halfmoveClock;
  Int8List get board => _board;

  bool isInsufficientMaterial() {
    var whiteKnights = 0;
    var blackKnights = 0;
    var bishopCount = 0;
    var firstBishopColor = -1;
    var allBishopsSameColor = true;

    for (var i = 0; i < 64; i++) {
      final p = _board[i];
      if (p == 0 || p == 6 || p == 14) continue;
      if (p == 1 || p == 9 || p == 4 || p == 12 || p == 5 || p == 13) {
        return false;
      }
      if (p == 2) {
        whiteKnights++;
      } else if (p == 10) {
        blackKnights++;
      } else if (p == 3 || p == 11) {
        bishopCount++;
        final sqColor = (i ~/ 8 + i % 8) % 2;
        if (firstBishopColor == -1) {
          firstBishopColor = sqColor;
        } else if (sqColor != firstBishopColor) {
          allBishopsSameColor = false;
        }
      }
    }

    if (whiteKnights == 0 && blackKnights == 0 && bishopCount == 0) {
      return true;
    }

    if (bishopCount == 0) {
      if ((whiteKnights == 1 && blackKnights == 0) ||
          (whiteKnights == 0 && blackKnights == 1)) {
        return true;
      }
      return false;
    }

    if (whiteKnights == 0 && blackKnights == 0 && bishopCount > 0) {
      return allBishopsSameColor;
    }

    return false;
  }

  void _loadPosition(GamePosition pos) {
    for (var i = 0; i < 64; i++) {
      final code = _charToPiece(pos.board[i]);
      _board[i] = code;
      if (code == 6) _whiteKingSq = i;
      if (code == 14) _blackKingSq = i;
    }
    _whiteToMove = pos.whiteToMove;

    _castlingRights = 0;
    if (pos.castling.contains('K')) _castlingRights |= 1;
    if (pos.castling.contains('Q')) _castlingRights |= 2;
    if (pos.castling.contains('k')) _castlingRights |= 4;
    if (pos.castling.contains('q')) _castlingRights |= 8;

    if (pos.enPassant != null) {
      _enPassantCol = pos.enPassant! % 8;
    } else {
      _enPassantCol = -1;
    }

    _halfmoveClock = pos.halfmoveClock;
    _zobristKey = computeZobristKey();
  }

  int computeZobristKey() {
    _Zobrist.ensureInitialized();
    var key = 0;
    for (var i = 0; i < 64; i++) {
      final p = _board[i];
      if (p != 0) {
        key ^= _Zobrist.piece[i][p];
      }
    }
    if (!_whiteToMove) {
      key ^= _Zobrist.sideToMove;
    }
    key ^= _Zobrist.castling[_castlingRights];
    if (_enPassantCol != -1) {
      key ^= _Zobrist.enPassant[_enPassantCol];
    }
    return key;
  }

  static int _charToPiece(String c) => switch (c) {
    'P' => 1,
    'N' => 2,
    'B' => 3,
    'R' => 4,
    'Q' => 5,
    'K' => 6,
    'p' => 9,
    'n' => 10,
    'b' => 11,
    'r' => 12,
    'q' => 13,
    'k' => 14,
    _ => 0,
  };

  static int moveFrom(int m) => m & 0x3F;
  static int moveTo(int m) => (m >> 6) & 0x3F;
  static int movePromo(int m) => (m >> 12) & 0x7;

  Move toMove(int move) {
    final from = moveFrom(move);
    final to = moveTo(move);
    final promoCode = movePromo(move);
    final promoChar = switch (promoCode) {
      2 => 'n',
      3 => 'b',
      4 => 'r',
      5 => 'q',
      _ => null,
    };
    return Move(from, to, promotion: promoChar);
  }

  int fromMove(Move move) {
    final buffer = <int>[];
    generateLegalMoves(buffer);
    final targetPromo = switch (move.promotion?.toLowerCase()) {
      'n' => 2,
      'b' => 3,
      'r' => 4,
      'q' => 5,
      _ => 0,
    };

    for (final m in buffer) {
      if (moveFrom(m) == move.from &&
          moveTo(m) == move.to &&
          movePromo(m) == targetPromo) {
        return m;
      }
    }
    throw ArgumentError('Illegal move: ${move.toUci()}');
  }

  bool isInCheck() {
    final kingSq = _whiteToMove ? _whiteKingSq : _blackKingSq;
    return _isSquareAttacked(kingSq, !_whiteToMove);
  }

  bool _isSquareAttacked(int sq, bool byWhite) {
    final x = sq ~/ 8;
    final y = sq % 8;

    // Tốt tấn công
    final pawnDir = byWhite ? 1 : -1;
    final px = x + pawnDir;
    if (px >= 0 && px < 8) {
      final pCode = byWhite ? 1 : 9;
      if (y > 0 && _board[px * 8 + (y - 1)] == pCode) return true;
      if (y < 7 && _board[px * 8 + (y + 1)] == pCode) return true;
    }

    // Mã tấn công
    final knightCode = byWhite ? 2 : 10;
    const knightSteps = [
      [-2, -1],
      [-2, 1],
      [-1, -2],
      [-1, 2],
      [1, -2],
      [1, 2],
      [2, -1],
      [2, 1],
    ];
    for (final s in knightSteps) {
      final nx = x + s[0];
      final ny = y + s[1];
      if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        if (_board[nx * 8 + ny] == knightCode) return true;
      }
    }

    // Vua tấn công
    final kingCode = byWhite ? 6 : 14;
    const kingSteps = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];
    for (final s in kingSteps) {
      final nx = x + s[0];
      final ny = y + s[1];
      if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        if (_board[nx * 8 + ny] == kingCode) return true;
      }
    }

    // Hướng thẳng: Xe, Hậu
    final rookCode = byWhite ? 4 : 12;
    final queenCode = byWhite ? 5 : 13;
    const straightDirs = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    for (final d in straightDirs) {
      var nx = x + d[0];
      var ny = y + d[1];
      while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        final p = _board[nx * 8 + ny];
        if (p != 0) {
          if (p == rookCode || p == queenCode) return true;
          break;
        }
        nx += d[0];
        ny += d[1];
      }
    }

    // Hướng chéo: Tượng, Hậu
    final bishopCode = byWhite ? 3 : 11;
    const diagDirs = [
      [-1, -1],
      [-1, 1],
      [1, -1],
      [1, 1],
    ];
    for (final d in diagDirs) {
      var nx = x + d[0];
      var ny = y + d[1];
      while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        final p = _board[nx * 8 + ny];
        if (p != 0) {
          if (p == bishopCode || p == queenCode) return true;
          break;
        }
        nx += d[0];
        ny += d[1];
      }
    }

    return false;
  }

  void generateLegalMoves(List<int> out) {
    out.clear();
    final buffer = _ply < 64 ? _moveBuffers[_ply] : <int>[];
    buffer.clear();
    _generatePseudoMoves(buffer, onlyCaptures: false);

    final movingSideIsWhite = _whiteToMove;
    for (var i = 0; i < buffer.length; i++) {
      final m = buffer[i];
      makeMove(m);
      final kingSq = movingSideIsWhite ? _whiteKingSq : _blackKingSq;
      final inCheck = _isSquareAttacked(kingSq, !movingSideIsWhite);
      unmakeMove();
      if (!inCheck) {
        out.add(m);
      }
    }
  }

  void generateCaptures(List<int> out) {
    out.clear();
    final buffer = _ply < 64 ? _moveBuffers[_ply] : <int>[];
    buffer.clear();
    _generatePseudoMoves(buffer, onlyCaptures: true);

    final movingSideIsWhite = _whiteToMove;
    for (var i = 0; i < buffer.length; i++) {
      final m = buffer[i];
      makeMove(m);
      final kingSq = movingSideIsWhite ? _whiteKingSq : _blackKingSq;
      final inCheck = _isSquareAttacked(kingSq, !movingSideIsWhite);
      unmakeMove();
      if (!inCheck) {
        out.add(m);
      }
    }
  }

  void _generatePseudoMoves(List<int> out, {required bool onlyCaptures}) {
    final usWhite = _whiteToMove;

    for (var sq = 0; sq < 64; sq++) {
      final p = _board[sq];
      if (p == 0) continue;
      final isPieceWhite = (p & 8) == 0;
      if (isPieceWhite != usWhite) continue;

      final type = p & 7;
      switch (type) {
        case 1: // Pawn
          _generatePawnMoves(sq, usWhite, out, onlyCaptures);
        case 2: // Knight
          _generateKnightMoves(sq, usWhite, out, onlyCaptures);
        case 3: // Bishop
          _generateSliderMoves(
            sq,
            usWhite,
            const [
              [-1, -1],
              [-1, 1],
              [1, -1],
              [1, 1],
            ],
            out,
            onlyCaptures,
          );
        case 4: // Rook
          _generateSliderMoves(
            sq,
            usWhite,
            const [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1],
            ],
            out,
            onlyCaptures,
          );
        case 5: // Queen
          _generateSliderMoves(
            sq,
            usWhite,
            const [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1],
              [-1, -1],
              [-1, 1],
              [1, -1],
              [1, 1],
            ],
            out,
            onlyCaptures,
          );
        case 6: // King
          _generateKingMoves(sq, usWhite, out, onlyCaptures);
      }
    }
  }

  void _generatePawnMoves(
    int from,
    bool isWhite,
    List<int> out,
    bool onlyCaptures,
  ) {
    final x = from ~/ 8;
    final y = from % 8;
    final dir = isWhite ? -1 : 1;
    final promoRank = isWhite ? 0 : 7;
    final startRank = isWhite ? 6 : 1;

    // Nước đi thẳng
    final toSq = (x + dir) * 8 + y;
    final isPromo = (x + dir) == promoRank;

    if (!onlyCaptures || isPromo) {
      if (_board[toSq] == 0) {
        if (isPromo) {
          for (final promo in const [5, 4, 3, 2]) {
            // Q, R, B, N
            out.add(from | (toSq << 6) | (promo << 12));
          }
        } else if (!onlyCaptures) {
          out.add(from | (toSq << 6));
          // Bước đôi
          if (x == startRank) {
            final toSq2 = (x + dir * 2) * 8 + y;
            if (_board[toSq2] == 0) {
              out.add(from | (toSq2 << 6) | flagPawnTwo);
            }
          }
        }
      }
    }

    // Nước ăn chéo
    for (final dy in const [-1, 1]) {
      final ny = y + dy;
      if (ny < 0 || ny > 7) continue;
      final capSq = (x + dir) * 8 + ny;
      final target = _board[capSq];

      if (target != 0) {
        final targetIsWhite = (target & 8) == 0;
        if (targetIsWhite != isWhite) {
          if (isPromo) {
            for (final promo in const [5, 4, 3, 2]) {
              out.add(from | (capSq << 6) | (promo << 12) | flagCapture);
            }
          } else {
            out.add(from | (capSq << 6) | flagCapture);
          }
        }
      } else if (_enPassantCol == ny) {
        // En passant
        final epExpectedRank = isWhite ? 2 : 5; // Rank đích của en passant
        if (x + dir == epExpectedRank) {
          out.add(from | (capSq << 6) | flagCapture | flagEnPassant);
        }
      }
    }
  }

  void _generateKnightMoves(
    int from,
    bool isWhite,
    List<int> out,
    bool onlyCaptures,
  ) {
    final x = from ~/ 8;
    final y = from % 8;
    const steps = [
      [-2, -1],
      [-2, 1],
      [-1, -2],
      [-1, 2],
      [1, -2],
      [1, 2],
      [2, -1],
      [2, 1],
    ];
    for (final s in steps) {
      final nx = x + s[0];
      final ny = y + s[1];
      if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        final toSq = nx * 8 + ny;
        final target = _board[toSq];
        if (target == 0) {
          if (!onlyCaptures) out.add(from | (toSq << 6));
        } else {
          final targetIsWhite = (target & 8) == 0;
          if (targetIsWhite != isWhite) {
            out.add(from | (toSq << 6) | flagCapture);
          }
        }
      }
    }
  }

  void _generateSliderMoves(
    int from,
    bool isWhite,
    List<List<int>> dirs,
    List<int> out,
    bool onlyCaptures,
  ) {
    final x = from ~/ 8;
    final y = from % 8;
    for (final d in dirs) {
      var nx = x + d[0];
      var ny = y + d[1];
      while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        final toSq = nx * 8 + ny;
        final target = _board[toSq];
        if (target == 0) {
          if (!onlyCaptures) out.add(from | (toSq << 6));
        } else {
          final targetIsWhite = (target & 8) == 0;
          if (targetIsWhite != isWhite) {
            out.add(from | (toSq << 6) | flagCapture);
          }
          break;
        }
        nx += d[0];
        ny += d[1];
      }
    }
  }

  void _generateKingMoves(
    int from,
    bool isWhite,
    List<int> out,
    bool onlyCaptures,
  ) {
    final x = from ~/ 8;
    final y = from % 8;
    const steps = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1],
    ];
    for (final s in steps) {
      final nx = x + s[0];
      final ny = y + s[1];
      if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        final toSq = nx * 8 + ny;
        final target = _board[toSq];
        if (target == 0) {
          if (!onlyCaptures) out.add(from | (toSq << 6));
        } else {
          final targetIsWhite = (target & 8) == 0;
          if (targetIsWhite != isWhite) {
            out.add(from | (toSq << 6) | flagCapture);
          }
        }
      }
    }

    if (onlyCaptures) return;

    // Nhập thành
    if (isWhite) {
      if (from == 60) {
        // e1
        // Kingside: e1 -> g1 (62)
        if ((_castlingRights & 1) != 0 &&
            _board[61] == 0 &&
            _board[62] == 0 &&
            !_isSquareAttacked(60, false) &&
            !_isSquareAttacked(61, false) &&
            !_isSquareAttacked(62, false)) {
          out.add(60 | (62 << 6) | flagCastle);
        }
        // Queenside: e1 -> c1 (58)
        if ((_castlingRights & 2) != 0 &&
            _board[59] == 0 &&
            _board[58] == 0 &&
            _board[57] == 0 &&
            !_isSquareAttacked(60, false) &&
            !_isSquareAttacked(59, false) &&
            !_isSquareAttacked(58, false)) {
          out.add(60 | (58 << 6) | flagCastle);
        }
      }
    } else {
      if (from == 4) {
        // e8
        // Kingside: e8 -> g8 (6)
        if ((_castlingRights & 4) != 0 &&
            _board[5] == 0 &&
            _board[6] == 0 &&
            !_isSquareAttacked(4, true) &&
            !_isSquareAttacked(5, true) &&
            !_isSquareAttacked(6, true)) {
          out.add(4 | (6 << 6) | flagCastle);
        }
        // Queenside: e8 -> c8 (2)
        if ((_castlingRights & 8) != 0 &&
            _board[3] == 0 &&
            _board[2] == 0 &&
            _board[1] == 0 &&
            !_isSquareAttacked(4, true) &&
            !_isSquareAttacked(3, true) &&
            !_isSquareAttacked(2, true)) {
          out.add(4 | (2 << 6) | flagCastle);
        }
      }
    }
  }

  void makeMove(int move) {
    final from = moveFrom(move);
    final to = moveTo(move);
    final promo = movePromo(move);
    final isCap = (move & flagCapture) != 0;
    final isEp = (move & flagEnPassant) != 0;
    final isCas = (move & flagCastle) != 0;
    final isTwo = (move & flagPawnTwo) != 0;

    // Lưu undo state
    final undo = _history[_ply++];
    undo.move = move;
    undo.capturedPiece = _board[to];
    undo.castlingRights = _castlingRights;
    undo.enPassantCol = _enPassantCol;
    undo.halfmoveClock = _halfmoveClock;
    undo.zobristKey = _zobristKey;

    final movingPiece = _board[from];
    final pieceType = movingPiece & 7;
    final isWhite = (movingPiece & 8) == 0;

    // Cập nhật Zobrist: xóa quân tại `from`
    _zobristKey ^= _Zobrist.piece[from][movingPiece];

    // Xóa quân bị ăn tại `to` (nếu có)
    if (isCap && !isEp) {
      _zobristKey ^= _Zobrist.piece[to][_board[to]];
    }

    // En passant capture
    if (isEp) {
      final capturedPawnSq = isWhite ? to + 8 : to - 8;
      final epPawn = _board[capturedPawnSq];
      undo.capturedPiece = epPawn; // lưu lại quân tốt bị ăn
      _board[capturedPawnSq] = 0;
      _zobristKey ^= _Zobrist.piece[capturedPawnSq][epPawn];
    }

    // Đặt quân tại `to` (hoặc quân phong cấp)
    var finalPiece = movingPiece;
    if (promo != 0) {
      finalPiece = isWhite ? promo : (promo | 8);
    }
    _board[to] = finalPiece;
    _board[from] = 0;
    _zobristKey ^= _Zobrist.piece[to][finalPiece];

    // Cập nhật vị trí vua
    if (pieceType == 6) {
      if (isWhite) {
        _whiteKingSq = to;
      } else {
        _blackKingSq = to;
      }
    }

    // Nhập thành: di chuyển Xe
    if (isCas) {
      if (to == 62) {
        // Trắng O-O: h1 -> f1
        _board[61] = 4;
        _board[63] = 0;
        _zobristKey ^= _Zobrist.piece[63][4] ^ _Zobrist.piece[61][4];
      } else if (to == 58) {
        // Trắng O-O-O: a1 -> d1
        _board[59] = 4;
        _board[56] = 0;
        _zobristKey ^= _Zobrist.piece[56][4] ^ _Zobrist.piece[59][4];
      } else if (to == 6) {
        // Đen O-O: h8 -> f8
        _board[5] = 12;
        _board[7] = 0;
        _zobristKey ^= _Zobrist.piece[7][12] ^ _Zobrist.piece[5][12];
      } else if (to == 2) {
        // Đen O-O-O: a8 -> d8
        _board[3] = 12;
        _board[0] = 0;
        _zobristKey ^= _Zobrist.piece[0][12] ^ _Zobrist.piece[3][12];
      }
    }

    // Cập nhật Zobrist cho enPassant cũ
    if (_enPassantCol != -1) {
      _zobristKey ^= _Zobrist.enPassant[_enPassantCol];
      _enPassantCol = -1;
    }

    // En passant mới nếu tốt đi 2 ô
    if (isTwo) {
      _enPassantCol = from % 8;
      _zobristKey ^= _Zobrist.enPassant[_enPassantCol];
    }

    // Cập nhật quyền nhập thành
    var newCastling = _castlingRights;
    if (movingPiece == 6) newCastling &= ~3; // White King
    if (movingPiece == 14) newCastling &= ~12; // Black King

    // Nếu xe di chuyển hoặc bị ăn
    if (from == 63 || to == 63) newCastling &= ~1;
    if (from == 56 || to == 56) newCastling &= ~2;
    if (from == 7 || to == 7) newCastling &= ~4;
    if (from == 0 || to == 0) newCastling &= ~8;

    if (newCastling != _castlingRights) {
      _zobristKey ^=
          _Zobrist.castling[_castlingRights] ^ _Zobrist.castling[newCastling];
      _castlingRights = newCastling;
    }

    // Cập nhật đồng hồ 50 nước
    if (pieceType == 1 || isCap) {
      _halfmoveClock = 0;
    } else {
      _halfmoveClock++;
    }

    // Đổi lượt đi
    _whiteToMove = !_whiteToMove;
    _zobristKey ^= _Zobrist.sideToMove;
  }

  void unmakeMove() {
    final undo = _history[--_ply];
    final move = undo.move;
    final from = moveFrom(move);
    final to = moveTo(move);
    final promo = movePromo(move);
    final isCap = (move & flagCapture) != 0;
    final isEp = (move & flagEnPassant) != 0;
    final isCas = (move & flagCastle) != 0;

    // Đổi lại lượt đi
    _whiteToMove = !_whiteToMove;
    final isWhite = _whiteToMove;

    // Khôi phục quân đi ban đầu
    var origPiece = _board[to];
    if (promo != 0) {
      origPiece = isWhite ? 1 : 9; // Tốt ban đầu
    }
    _board[from] = origPiece;
    _board[to] = isCap && !isEp ? undo.capturedPiece : 0;

    // Cập nhật lại vị trí vua
    if ((origPiece & 7) == 6) {
      if (isWhite) {
        _whiteKingSq = from;
      } else {
        _blackKingSq = from;
      }
    }

    // Khôi phục en passant
    if (isEp) {
      final capturedPawnSq = isWhite ? to + 8 : to - 8;
      _board[capturedPawnSq] = undo.capturedPiece;
    }

    // Khôi phục xe nhập thành
    if (isCas) {
      if (to == 62) {
        // Trắng O-O
        _board[63] = 4;
        _board[61] = 0;
      } else if (to == 58) {
        // Trắng O-O-O
        _board[56] = 4;
        _board[59] = 0;
      } else if (to == 6) {
        // Đen O-O
        _board[7] = 12;
        _board[5] = 0;
      } else if (to == 2) {
        // Đen O-O-O
        _board[0] = 12;
        _board[3] = 0;
      }
    }

    _castlingRights = undo.castlingRights;
    _enPassantCol = undo.enPassantCol;
    _halfmoveClock = undo.halfmoveClock;
    _zobristKey = undo.zobristKey;
  }
}
