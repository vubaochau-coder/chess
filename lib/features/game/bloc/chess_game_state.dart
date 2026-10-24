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
    required this.config,
    required this.gameId,
    required this.isAiThinking,
    required this.history,
    required this.status,
    this.moves = const [],
    this.selected,
    this.legalTargets = const [],
    this.checkSquare,
    this.pendingPromotion,
  });

  factory ChessGameState.initial(
    GamePosition start, {
    required GameConfig config,
    int gameId = 0,
  }) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      isAiThinking: false,
      history: [start],
      moves: const [],
      status: ChessRules.gameStatus([start]),
      checkSquare: _checkSquareOf(start),
    );
  }

  factory ChessGameState.restore(SavedGame restore, {int gameId = 0}) {
    final start = Fen.parse(restore.startFen);
    var current = ChessGameState.initial(
      start,
      config: restore.config,
      gameId: gameId,
    );

    for (final uci in restore.moves) {
      final move = Move.fromUci(uci);
      final before = current.position;
      final san = San.format(before, move);
      final type = before.board[move.from].toLowerCase();
      final isEnPassant = type == 'p' && move.to == before.enPassant;
      final captured = isEnPassant
          ? before.board[(move.from ~/ 8) * 8 + (move.to % 8)]
          : (before.board[move.to].isNotEmpty ? before.board[move.to] : null);
      final record = MoveRecord(move: move, san: san, captured: captured);
      final result = ChessRules.applyMove(
        before,
        move.from,
        move.to,
        promotion: move.promotion ?? 'q',
      );
      current = current.afterMove(result.position, record);
    }

    return current;
  }

  final GameConfig config;

  final int gameId;

  final bool isAiThinking;

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

  /// Kiểm tra có phải lượt của người chơi hay không.
  bool get isHumanTurn {
    if (config.mode == GameMode.pvp) return true;
    final isWhiteTurn = position.whiteToMove;
    return config.humanColor == PieceColor.white ? isWhiteTurn : !isWhiteTurn;
  }

  /// Kiểm tra nút Undo có được bật hay không.
  bool get canUndo {
    if (status == GameStatus.whiteResigned ||
        status == GameStatus.blackResigned) {
      return false;
    }
    if (config.mode == GameMode.pvp) {
      return history.length > 1;
    }
    // pve: phải có ít nhất 1 nước của người trong lịch sử nước đi.
    final isWhiteHuman = config.humanColor == PieceColor.white;
    for (var i = 0; i < moves.length; i++) {
      if (i.isEven == isWhiteHuman) return true;
    }
    return false;
  }

  /// Trạng thái sau khi người chơi hoặc bên tới lượt đầu hàng.
  ChessGameState resigned(GameStatus resignStatus) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      isAiThinking: false,
      history: history,
      moves: moves,
      status: resignStatus,
      checkSquare: checkSquare,
    );
  }

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
      config: config,
      gameId: gameId,
      isAiThinking: false,
      history: nextHistory,
      moves: nextMoves,
      status: ChessRules.gameStatus(nextHistory),
      checkSquare: _checkSquareOf(next),
    );
  }

  /// Trạng thái sau khi quay lại nước đi.
  ChessGameState undo() {
    if (!canUndo) return this;
    if (config.mode == GameMode.pvp) {
      final nextHistory = history.sublist(0, history.length - 1);
      final nextMoves = moves.sublist(0, moves.length - 1);
      return ChessGameState(
        config: config,
        gameId: gameId,
        isAiThinking: false,
        history: nextHistory,
        moves: nextMoves,
        status: ChessRules.gameStatus(nextHistory),
        checkSquare: _checkSquareOf(nextHistory.last),
      );
    }

    // pve: quay lại tới lượt người gần nhất có nước người đã đi
    var lastHumanMoveIndex = -1;
    final isWhiteHuman = config.humanColor == PieceColor.white;
    for (var i = moves.length - 1; i >= 0; i--) {
      if (i.isEven == isWhiteHuman) {
        lastHumanMoveIndex = i;
        break;
      }
    }
    if (lastHumanMoveIndex == -1) return this;
    final nextHistory = history.sublist(0, lastHumanMoveIndex + 1);
    final nextMoves = moves.sublist(0, lastHumanMoveIndex);
    return ChessGameState(
      config: config,
      gameId: gameId,
      isAiThinking: false,
      history: nextHistory,
      moves: nextMoves,
      status: ChessRules.gameStatus(nextHistory),
      checkSquare: _checkSquareOf(nextHistory.last),
    );
  }

  ChessGameState withSelection(int square, List<int> targets) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      isAiThinking: isAiThinking,
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
      config: config,
      gameId: gameId,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      checkSquare: checkSquare,
    );
  }

  ChessGameState withPendingPromotion(LastMove move) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      isAiThinking: isAiThinking,
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
      config: config,
      gameId: gameId,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      checkSquare: checkSquare,
    );
  }

  ChessGameState copyWith({
    GameConfig? config,
    int? gameId,
    bool? isAiThinking,
    List<GamePosition>? history,
    List<MoveRecord>? moves,
    GameStatus? status,
    int? selected,
    List<int>? legalTargets,
    int? checkSquare,
    LastMove? pendingPromotion,
  }) {
    return ChessGameState(
      config: config ?? this.config,
      gameId: gameId ?? this.gameId,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      history: history ?? this.history,
      moves: moves ?? this.moves,
      status: status ?? this.status,
      selected: selected ?? this.selected,
      legalTargets: legalTargets ?? this.legalTargets,
      checkSquare: checkSquare ?? this.checkSquare,
      pendingPromotion: pendingPromotion ?? this.pendingPromotion,
    );
  }

  @override
  List<Object?> get props => [
    config,
    gameId,
    isAiThinking,
    history,
    moves,
    status,
    selected,
    legalTargets,
    checkSquare,
    pendingPromotion,
  ];
}
