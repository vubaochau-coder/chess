import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/engine/square.dart';
import 'package:chess/core/tutorial/lesson.dart';
import 'package:equatable/equatable.dart';

enum LessonResult { playing, success, failed }

/// Bàn cờ của một bài học. Chỉ quân Trắng được đi và không có máy đáp trả,
/// nên khi bài còn tiếp tục thì sau mỗi nước vẫn tới lượt Trắng.
final class LessonBoard extends Equatable {
  const LessonBoard._({
    required this.lesson,
    required this.position,
    this.selected,
    this.targets = const [],
    this.lastMove,
    this.movesMade = 0,
    this.result = LessonResult.playing,
  });

  factory LessonBoard.start(Lesson lesson) =>
      LessonBoard._(lesson: lesson, position: Fen.parse(lesson.fen));

  final Lesson lesson;
  final GamePosition position;
  final int? selected;
  final List<int> targets;
  final Move? lastMove;
  final int movesMade;
  final LessonResult result;

  /// Ô đích của thử thách [ChallengeKind.reach], nếu có.
  int? get targetSquare {
    final name = lesson.challenge?.target;
    return name == null ? null : squareFromName(name);
  }

  List<int> get highlightSquares =>
      lesson.highlights.map(squareFromName).toList();

  LessonBoard tap(int square) {
    if (result != LessonResult.playing) return this;

    final from = selected;
    if (from != null && targets.contains(square)) {
      return _move(from, square);
    }

    final piece = position.board[square];
    if (piece.isNotEmpty && ChessRules.isWhite(piece) && square != from) {
      return LessonBoard._(
        lesson: lesson,
        position: position,
        selected: square,
        targets: ChessRules.legalMoves(position, square),
        lastMove: lastMove,
        movesMade: movesMade,
      );
    }

    return LessonBoard._(
      lesson: lesson,
      position: position,
      lastMove: lastMove,
      movesMade: movesMade,
    );
  }

  LessonBoard _move(int from, int to) {
    final after = ChessRules.applyMove(position, from, to).position;
    final move = Move(from, to);
    final moves = movesMade + 1;
    final result = _evaluate(after, move, moves);

    final next = result == LessonResult.playing
        ? GamePosition(
            board: after.board,
            castling: after.castling,
            halfmoveClock: after.halfmoveClock,
            fullmoveNumber: after.fullmoveNumber,
          )
        : after;

    return LessonBoard._(
      lesson: lesson,
      position: next,
      lastMove: move,
      movesMade: moves,
      result: result,
    );
  }

  LessonResult _evaluate(GamePosition after, Move move, int moves) {
    final challenge = lesson.challenge;
    if (challenge == null) return LessonResult.playing;

    switch (challenge.kind) {
      case ChallengeKind.reach:
        final target = targetSquare;
        final piece = target == null ? '' : after.board[target];
        if (piece.isNotEmpty && ChessRules.isWhite(piece)) {
          return LessonResult.success;
        }
        return moves >= challenge.maxMoves
            ? LessonResult.failed
            : LessonResult.playing;
      case ChallengeKind.giveCheck:
        return _verdict(ChessRules.isInCheck(after.board, false));
      case ChallengeKind.checkmate:
        return _verdict(ChessRules.status(after) == GameStatus.checkmate);
      case ChallengeKind.playMove:
        return _verdict(challenge.acceptedMoves.contains(move.toUci()));
    }
  }

  static LessonResult _verdict(bool ok) =>
      ok ? LessonResult.success : LessonResult.failed;

  @override
  List<Object?> get props => [
    lesson.id,
    Fen.format(position),
    selected,
    targets,
    lastMove,
    movesMade,
    result,
  ];
}
