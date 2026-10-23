import 'package:bloc/bloc.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
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
    if (state.isGameOver) return;

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

    final result = ChessRules.applyMove(state.position, from, square);
    final next = state.afterMove(result.position, (from: from, to: square));
    _sound.play(_moveSound(result, next.status));
    emit(next);
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
