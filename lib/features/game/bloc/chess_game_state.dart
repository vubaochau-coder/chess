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
    this.flipped = false,
    this.undosUsed = 0,
    this.hintsUsed = 0,
    this.undoLockedAt,
    this.hint,
    this.isHintLoading = false,
  });

  /// Số lần đi lại tối đa mỗi ván khi chơi với máy.
  static const maxUndos = 3;

  /// Số lần gợi ý tối đa mỗi ván khi chơi với máy.
  static const maxHints = 3;

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
      flipped: _startsFlipped(config),
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

    return current._withCounters(
      undosUsed: restore.undosUsed,
      hintsUsed: restore.hintsUsed,
      undoLockedAt: restore.undoLockedAt,
    );
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

  /// Bàn cờ hiển thị lật (quân Đen ở phía dưới).
  final bool flipped;

  /// Số lần đã đi lại trong ván (chỉ PvE).
  final int undosUsed;

  /// Số lần đã dùng gợi ý trong ván (chỉ PvE).
  final int hintsUsed;

  /// Số nước tại thời điểm vừa đi lại; phải đi thêm nước mới được đi lại tiếp.
  final int? undoLockedAt;

  /// Nước gợi ý đang hiện trên bàn cờ.
  final Move? hint;

  /// Đang tính nước gợi ý.
  final bool isHintLoading;

  int get undosLeft => maxUndos - undosUsed;

  int get hintsLeft => maxHints - hintsUsed;

  GamePosition get position => history.last;

  bool get isGameOver => status.isGameOver;

  /// Kiểm tra có phải lượt của người chơi hay không.
  bool get isHumanTurn {
    if (config.mode == GameMode.pvp) return true;
    final isWhiteTurn = position.whiteToMove;
    return config.humanColor == PieceColor.white ? isWhiteTurn : !isWhiteTurn;
  }

  /// Kiểm tra nút Undo có được bật hay không. Chơi 2 người không được đi lại.
  bool get canUndo {
    if (config.mode == GameMode.pvp) return false;
    if (status == GameStatus.whiteResigned ||
        status == GameStatus.blackResigned) {
      return false;
    }
    if (undosLeft <= 0) return false;
    if (undoLockedAt case final locked? when moves.length <= locked) {
      return false;
    }
    // pve: phải có ít nhất 1 nước của người trong lịch sử nước đi.
    final isWhiteHuman = config.humanColor == PieceColor.white;
    for (var i = 0; i < moves.length; i++) {
      if (i.isEven == isWhiteHuman) return true;
    }
    return false;
  }

  /// Có thể xin gợi ý nước đi (chỉ khi chơi với máy, tới lượt người).
  bool get canHint =>
      config.mode == GameMode.pve &&
      !isGameOver &&
      isHumanTurn &&
      !isAiThinking &&
      !isHintLoading &&
      hint == null &&
      pendingPromotion == null &&
      hintsLeft > 0;

  /// Trạng thái sau khi người chơi hoặc bên tới lượt đầu hàng.
  ChessGameState resigned(GameStatus resignStatus) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      flipped: flipped,
      isAiThinking: false,
      history: history,
      moves: moves,
      status: resignStatus,
      checkSquare: checkSquare,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
    );
  }

  /// Người cầm Đen khi chơi với máy thì bàn cờ lật (quân Đen ở dưới).
  static bool _startsFlipped(GameConfig config) =>
      config.mode == GameMode.pve && config.humanColor == PieceColor.black;

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
      flipped: flipped,
      isAiThinking: false,
      history: nextHistory,
      moves: nextMoves,
      status: ChessRules.gameStatus(nextHistory),
      checkSquare: _checkSquareOf(next),
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
    );
  }

  /// Trạng thái sau khi quay lại nước đi.
  ChessGameState undo() {
    if (!canUndo) return this;
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
      flipped: flipped,
      isAiThinking: false,
      history: nextHistory,
      moves: nextMoves,
      status: ChessRules.gameStatus(nextHistory),
      checkSquare: _checkSquareOf(nextHistory.last),
      undosUsed: undosUsed + 1,
      hintsUsed: hintsUsed,
      undoLockedAt: nextMoves.length,
    );
  }

  ChessGameState withSelection(int square, List<int> targets) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      flipped: flipped,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      selected: square,
      legalTargets: targets,
      checkSquare: checkSquare,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
      hint: hint,
      isHintLoading: isHintLoading,
    );
  }

  ChessGameState withoutSelection() {
    return ChessGameState(
      config: config,
      gameId: gameId,
      flipped: flipped,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      checkSquare: checkSquare,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
      hint: hint,
      isHintLoading: isHintLoading,
    );
  }

  ChessGameState withPendingPromotion(LastMove move) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      flipped: flipped,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      selected: selected,
      legalTargets: legalTargets,
      checkSquare: checkSquare,
      pendingPromotion: move,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
      hint: hint,
      isHintLoading: isHintLoading,
    );
  }

  ChessGameState withoutPendingPromotion() {
    return ChessGameState(
      config: config,
      gameId: gameId,
      flipped: flipped,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      checkSquare: checkSquare,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
      hint: hint,
      isHintLoading: isHintLoading,
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
    bool? flipped,
    bool? isHintLoading,
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
      flipped: flipped ?? this.flipped,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
      hint: hint,
      isHintLoading: isHintLoading ?? this.isHintLoading,
    );
  }

  /// Trạng thái hiện gợi ý [move]; tính là đã dùng một lượt gợi ý.
  ChessGameState withHint(Move move) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      flipped: flipped,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      selected: selected,
      legalTargets: legalTargets,
      checkSquare: checkSquare,
      pendingPromotion: pendingPromotion,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed + 1,
      undoLockedAt: undoLockedAt,
      hint: move,
    );
  }

  ChessGameState _withCounters({
    required int undosUsed,
    required int hintsUsed,
    required int? undoLockedAt,
  }) {
    return ChessGameState(
      config: config,
      gameId: gameId,
      flipped: flipped,
      isAiThinking: isAiThinking,
      history: history,
      moves: moves,
      status: status,
      checkSquare: checkSquare,
      undosUsed: undosUsed,
      hintsUsed: hintsUsed,
      undoLockedAt: undoLockedAt,
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
    flipped,
    undosUsed,
    hintsUsed,
    undoLockedAt,
    hint,
    isHintLoading,
  ];
}
