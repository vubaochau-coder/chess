import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/square.dart';

abstract final class Fen {
  static const String initial =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static GamePosition parse(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length != 4 && parts.length != 6) {
      throw FormatException('Invalid FEN fields count: ${parts.length}');
    }

    final rows = parts[0].split('/');
    if (rows.length != 8) {
      throw FormatException('FEN must have 8 ranks: ${parts[0]}');
    }

    final board = List<String>.filled(64, '');
    var whiteKings = 0;
    var blackKings = 0;

    final digit1 = '1'.codeUnitAt(0);
    final digit8 = '8'.codeUnitAt(0);

    for (var r = 0; r < 8; r++) {
      final rowStr = rows[r];
      var col = 0;
      var lastWasDigit = false;
      for (var i = 0; i < rowStr.length; i++) {
        final c = rowStr[i];
        final code = c.codeUnitAt(0);
        if (code >= digit1 && code <= digit8) {
          if (lastWasDigit) {
            throw FormatException('Rank $r has consecutive digits: $rowStr');
          }
          lastWasDigit = true;
          final emptyCount = int.parse(c);
          col += emptyCount;
          if (col > 8) {
            throw FormatException('Rank $r has more than 8 squares');
          }
        } else if (_isPieceChar(c)) {
          lastWasDigit = false;
          if (col >= 8) {
            throw FormatException('Rank $r has more than 8 squares');
          }
          board[r * 8 + col] = c;
          if (c == 'K') whiteKings++;
          if (c == 'k') blackKings++;
          col++;
        } else {
          throw FormatException('Invalid piece character in FEN: $c');
        }
      }
      if (col != 8) {
        throw FormatException('Rank $r does not have 8 squares (has $col)');
      }
    }

    if (whiteKings != 1 || blackKings != 1) {
      throw FormatException(
        'Each side must have exactly 1 king (white: $whiteKings, black: $blackKings)',
      );
    }

    if (parts[1] != 'w' && parts[1] != 'b') {
      throw FormatException('Invalid active color: ${parts[1]}');
    }
    final whiteToMove = parts[1] == 'w';

    final castlingStr = parts[2];
    var castling = '';
    if (castlingStr != '-') {
      final seen = <String>{};
      for (var i = 0; i < castlingStr.length; i++) {
        final ch = castlingStr[i];
        if (ch != 'K' && ch != 'Q' && ch != 'k' && ch != 'q') {
          throw FormatException('Invalid castling character: $ch');
        }
        if (seen.contains(ch)) {
          throw FormatException('Duplicate castling character: $ch');
        }
        seen.add(ch);
      }
      castling = castlingStr;
    }

    final epStr = parts[3];
    int? enPassant;
    if (epStr != '-') {
      if (epStr.length != 2) {
        throw FormatException('Invalid en passant square: $epStr');
      }
      final rank = epStr[1];
      if (rank != '3' && rank != '6') {
        throw FormatException(
          'En passant square must be on rank 3 or 6: $epStr',
        );
      }
      enPassant = squareFromName(epStr);
    }

    var halfmoveClock = 0;
    var fullmoveNumber = 1;
    if (parts.length == 6) {
      final half = int.tryParse(parts[4]);
      if (half == null || half < 0) {
        throw FormatException(
          'Halfmove clock must be an integer >= 0: ${parts[4]}',
        );
      }
      halfmoveClock = half;

      final full = int.tryParse(parts[5]);
      if (full == null || full < 1) {
        throw FormatException(
          'Fullmove number must be an integer >= 1: ${parts[5]}',
        );
      }
      fullmoveNumber = full;
    }

    return GamePosition(
      board: board,
      whiteToMove: whiteToMove,
      castling: castling,
      enPassant: enPassant,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmoveNumber,
    );
  }

  static String format(GamePosition position) {
    final rowStrings = <String>[];
    for (var r = 0; r < 8; r++) {
      final sb = StringBuffer();
      var emptyCount = 0;
      for (var c = 0; c < 8; c++) {
        final piece = position.board[r * 8 + c];
        if (piece.isEmpty) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            sb.write(emptyCount);
            emptyCount = 0;
          }
          sb.write(piece);
        }
      }
      if (emptyCount > 0) {
        sb.write(emptyCount);
      }
      rowStrings.add(sb.toString());
    }
    final boardStr = rowStrings.join('/');

    final activeColor = position.whiteToMove ? 'w' : 'b';

    final castlingBuf = StringBuffer();
    if (position.castling.contains('K')) castlingBuf.write('K');
    if (position.castling.contains('Q')) castlingBuf.write('Q');
    if (position.castling.contains('k')) castlingBuf.write('k');
    if (position.castling.contains('q')) castlingBuf.write('q');
    final castlingStr = castlingBuf.isEmpty ? '-' : castlingBuf.toString();

    final epStr = position.enPassant != null
        ? squareName(position.enPassant!)
        : '-';

    return '$boardStr $activeColor $castlingStr $epStr ${position.halfmoveClock} ${position.fullmoveNumber}';
  }

  static bool _isPieceChar(String c) {
    const valid = 'pnbrqkPNBRQK';
    return valid.contains(c);
  }
}
