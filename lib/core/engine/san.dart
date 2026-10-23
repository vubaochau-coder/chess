import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/engine/square.dart';

abstract final class San {
  static String format(GamePosition before, Move move) {
    final piece = before.board[move.from];
    if (piece.isEmpty) {
      throw ArgumentError('No piece at square ${move.from}');
    }
    final type = piece.toLowerCase();
    final isCastle = type == 'k' && (move.to - move.from).abs() == 2;

    String san;
    if (isCastle) {
      san = move.to > move.from ? 'O-O' : 'O-O-O';
    } else {
      final isEnPassant = type == 'p' && move.to == before.enPassant;
      final isCapture = before.board[move.to].isNotEmpty || isEnPassant;

      if (type == 'p') {
        if (isCapture) {
          final fromFile = squareName(move.from)[0];
          san = '${fromFile}x${squareName(move.to)}';
        } else {
          san = squareName(move.to);
        }
        if (move.promotion != null) {
          san += '=${move.promotion!.toUpperCase()}';
        }
      } else {
        final pieceLetter = type.toUpperCase();
        var disambiguation = '';

        final otherCandidates = <int>[];
        for (var sq = 0; sq < 64; sq++) {
          if (sq == move.from) continue;
          if (before.board[sq] == piece) {
            if (ChessRules.legalMoves(before, sq).contains(move.to)) {
              otherCandidates.add(sq);
            }
          }
        }

        if (otherCandidates.isNotEmpty) {
          final fromFile = move.from % 8;
          final fromRank = move.from ~/ 8;

          final sameFile = otherCandidates.any((sq) => sq % 8 == fromFile);
          final sameRank = otherCandidates.any((sq) => sq ~/ 8 == fromRank);

          if (!sameFile) {
            disambiguation = squareName(move.from)[0];
          } else if (!sameRank) {
            disambiguation = squareName(move.from)[1];
          } else {
            disambiguation = squareName(move.from);
          }
        }

        final captureChar = isCapture ? 'x' : '';
        san = '$pieceLetter$disambiguation$captureChar${squareName(move.to)}';
      }
    }

    final after = ChessRules.applyMove(
      before,
      move.from,
      move.to,
      promotion: move.promotion ?? 'q',
    ).position;

    final nextStatus = ChessRules.status(after);
    if (nextStatus == GameStatus.checkmate) {
      san += '#';
    } else if (nextStatus == GameStatus.check) {
      san += '+';
    }

    return san;
  }
}
