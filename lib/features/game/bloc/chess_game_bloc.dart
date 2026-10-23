import 'package:bloc/bloc.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/engine/san.dart';
import 'package:equatable/equatable.dart';

part 'chess_game_event.dart';
part 'chess_game_state.dart';

class ChessGameBloc extends Bloc<ChessGameEvent, ChessGameState> {
  ChessGameBloc({required SoundPlayer soundPlayer, GamePosition? startPosition})
    : this._(soundPlayer, startPosition ?? GamePosition.initial());

  ChessGameBloc._(this._sound, this._start)
    : super(ChessGameState.initial(_start)) {
    on<NewGameRequested>(_onNewGameRequested);
    on<SquareTapped>(_onSquareTapped);
    on<PromotionPieceSelected>(_onPromotionPieceSelected);
    on<PromotionCancelled>(_onPromotionCancelled);
    on<UndoRequested>(_onUndoRequested);
  }

  // Bloc không sở hữu SoundPlayer nên không dispose nó trong close().
  final SoundPlayer _sound;
  final GamePosition _start;

  void _onNewGameRequested(
    NewGameRequested event,
    Emitter<ChessGameState> emit,
  ) {
    emit(ChessGameState.initial(_start));
  }

  void _onSquareTapped(SquareTapped event, Emitter<ChessGameState> emit) {
    if (state.isGameOver || state.pendingPromotion != null) return;

    final square = event.index;
    final piece = state.position.board[square];
    final isOwnPiece =
        piece.isNotEmpty &&
        ChessRules.isWhite(piece) == state.position.whiteToMove;

    if (isOwnPiece) {
      _sound.play(SoundEffect.select);
      if (state.selected == square) {
        emit(state.withoutSelection());
      } else {
        emit(
          state.withSelection(
            square,
            ChessRules.legalMoves(state.position, square),
          ),
        );
      }
      return;
    }

    final from = state.selected;
    if (from == null) return;

    if (!state.legalTargets.contains(square)) {
      _sound.play(SoundEffect.illegal);
      return;
    }

    if (ChessRules.isPromotionMove(state.position, from, square)) {
      emit(state.withPendingPromotion((from: from, to: square)));
      return;
    }

    final record = _createRecord(from, square);
    final result = ChessRules.applyMove(state.position, from, square);
    final next = state.afterMove(result.position, record);
    _sound.play(_moveSound(result, next.status));
    emit(next);
  }

  void _onPromotionPieceSelected(
    PromotionPieceSelected event,
    Emitter<ChessGameState> emit,
  ) {
    final pending = state.pendingPromotion;
    if (pending == null) return;

    final record = _createRecord(
      pending.from,
      pending.to,
      promotion: event.piece,
    );
    final result = ChessRules.applyMove(
      state.position,
      pending.from,
      pending.to,
      promotion: event.piece,
    );
    final next = state.afterMove(result.position, record);
    _sound.play(_moveSound(result, next.status));
    emit(next);
  }

  void _onPromotionCancelled(
    PromotionCancelled event,
    Emitter<ChessGameState> emit,
  ) {
    if (state.pendingPromotion == null) return;
    emit(state.withoutPendingPromotion());
  }

  void _onUndoRequested(UndoRequested event, Emitter<ChessGameState> emit) {
    if (state.history.length <= 1) return;
    emit(state.undo());
  }

  MoveRecord _createRecord(int from, int to, {String? promotion}) {
    final before = state.position;
    final move = Move(from, to, promotion: promotion);
    final san = San.format(before, move);
    final type = before.board[from].toLowerCase();
    final isEnPassant = type == 'p' && to == before.enPassant;
    final captured = isEnPassant
        ? before.board[(from ~/ 8) * 8 + (to % 8)]
        : (before.board[to].isNotEmpty ? before.board[to] : null);
    return MoveRecord(move: move, san: san, captured: captured);
  }

  SoundEffect _moveSound(MoveResult result, GameStatus status) {
    if (status.isGameOver) {
      return SoundEffect.gameEnd;
    }
    return switch (status) {
      GameStatus.check => SoundEffect.check,
      GameStatus.playing when result.isPromotion => SoundEffect.promote,
      GameStatus.playing when result.isCastle => SoundEffect.castle,
      GameStatus.playing when result.isCapture => SoundEffect.capture,
      _ => SoundEffect.move,
    };
  }
}
