part of 'chess_game_bloc.dart';

typedef LastMove = ({int from, int to});

final class ChessGameState extends Equatable {
  const ChessGameState({
    required this.history,
    required this.status,
    this.selected,
    this.legalTargets = const [],
    this.lastMove,
    this.checkSquare,
    this.pendingPromotion,
  });

  factory ChessGameState.initial(GamePosition start) {
    return ChessGameState(
      history: [start],
      status: ChessRules.gameStatus([start]),
      checkSquare: _checkSquareOf(start),
    );
  }

  /// Các thế cờ từ đầu ván; phần tử cuối là thế cờ hiện tại. Không sửa tại
  /// chỗ — mỗi nước đi tạo list mới.
  final List<GamePosition> history;
  final GameStatus status;

  /// Ô của quân đang được chọn.
  final int? selected;

  /// Các ô quân đang chọn có thể đi tới (đã lọc nước làm vua bị chiếu).
  final List<int> legalTargets;

  final LastMove? lastMove;

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

  /// Trạng thái sau khi đi một nước tới thế cờ [next].
  ChessGameState afterMove(GamePosition next, LastMove move) {
    final nextHistory = [...history, next];
    return ChessGameState(
      history: nextHistory,
      status: ChessRules.gameStatus(nextHistory),
      lastMove: move,
      checkSquare: _checkSquareOf(next),
    );
  }

  ChessGameState withSelection(int square, List<int> targets) {
    return ChessGameState(
      history: history,
      status: status,
      selected: square,
      legalTargets: targets,
      lastMove: lastMove,
      checkSquare: checkSquare,
    );
  }

  ChessGameState withoutSelection() {
    return ChessGameState(
      history: history,
      status: status,
      lastMove: lastMove,
      checkSquare: checkSquare,
    );
  }

  ChessGameState withPendingPromotion(LastMove move) {
    return ChessGameState(
      history: history,
      status: status,
      selected: selected,
      legalTargets: legalTargets,
      lastMove: lastMove,
      checkSquare: checkSquare,
      pendingPromotion: move,
    );
  }

  ChessGameState withoutPendingPromotion() {
    return ChessGameState(
      history: history,
      status: status,
      lastMove: lastMove,
      checkSquare: checkSquare,
    );
  }

  @override
  List<Object?> get props => [
    history,
    status,
    selected,
    legalTargets,
    lastMove,
    checkSquare,
    pendingPromotion,
  ];
}
