part of 'chess_game_bloc.dart';

typedef LastMove = ({int from, int to});

final class MoveRecord extends Equatable {
  const MoveRecord({required this.move, required this.san, this.captured});

  final Move move;
  final String san;
  final String? captured;

  @override
  List<Object?> get props => [move, san, captured];
}

final class ChessGameState extends Equatable {
  const ChessGameState({
    required this.history,
    required this.status,
    this.moves = const [],
    this.selected,
    this.legalTargets = const [],
    this.checkSquare,
    this.pendingPromotion,
  });

  factory ChessGameState.initial(GamePosition start) {
    return ChessGameState(
      history: [start],
      moves: const [],
      status: ChessRules.gameStatus([start]),
      checkSquare: _checkSquareOf(start),
    );
  }

  /// Các thế cờ từ đầu ván; phần tử cuối là thế cờ hiện tại. Không sửa tại
  /// chỗ — mỗi nước đi tạo list mới.
  final List<GamePosition> history;

  /// Lịch sử các nước đi đã thực hiện. Bất biến: moves.length == history.length - 1.
  final List<MoveRecord> moves;

  final GameStatus status;

  /// Ô của quân đang được chọn.
  final int? selected;

  /// Các ô quân đang chọn có thể đi tới (đã lọc nước làm vua bị chiếu).
  final List<int> legalTargets;

  /// Nước đi mới nhất suy ra từ [moves].
  LastMove? get lastMove => moves.isEmpty
      ? null
      : (from: moves.last.move.from, to: moves.last.move.to);

  /// Ô của vua đang bị chiếu (để tô đỏ), null nếu không bị chiếu.
  final int? checkSquare;

  /// Nước đi phong cấp đang chờ người chơi chọn quân.
  final LastMove? pendingPromotion;

  GamePosition get position => history.last;

  bool get isGameOver => status.isGameOver;

  static int? _checkSquareOf(GamePosition position) {
    if (!ChessRules.isInCheck(position.board, position.whiteToMove)) {
      return null;
    }
    return position.board.indexOf(position.whiteToMove ? 'K' : 'k');
  }

  /// Trạng thái sau khi đi một nước tới thế cờ [next] cùng bản ghi [record].
  ChessGameState afterMove(GamePosition next, MoveRecord record) {
    final nextHistory = [...history, next];
    final nextMoves = [...moves, record];
    return ChessGameState(
      history: nextHistory,
      moves: nextMoves,
      status: ChessRules.gameStatus(nextHistory),
      checkSquare: _checkSquareOf(next),
    );
  }

  ChessGameState withSelection(int square, List<int> targets) {
    return ChessGameState(
      history: history,
      moves: moves,
      status: status,
      selected: square,
      legalTargets: targets,
      checkSquare: checkSquare,
    );
  }

  ChessGameState withoutSelection() {
    return ChessGameState(
      history: history,
      moves: moves,
      status: status,
      checkSquare: checkSquare,
    );
  }

  ChessGameState withPendingPromotion(LastMove move) {
    return ChessGameState(
      history: history,
      moves: moves,
      status: status,
      selected: selected,
      legalTargets: legalTargets,
      checkSquare: checkSquare,
      pendingPromotion: move,
    );
  }

  ChessGameState withoutPendingPromotion() {
    return ChessGameState(
      history: history,
      moves: moves,
      status: status,
      checkSquare: checkSquare,
    );
  }

  @override
  List<Object?> get props => [
    history,
    moves,
    status,
    selected,
    legalTargets,
    checkSquare,
    pendingPromotion,
  ];
}
