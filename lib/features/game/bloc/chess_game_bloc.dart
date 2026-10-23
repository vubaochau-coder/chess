import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:chess/core/audio/chess_sounds.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/chess_utils.dart';
import 'package:equatable/equatable.dart';

part 'chess_game_event.dart';
part 'chess_game_state.dart';

class ChessGameBloc extends Bloc<ChessGameEvent, ChessGameState> {
  late final AudioPlayer player;

  ChessGameBloc() : super(const ChessGameState()) {
    player = AudioPlayer();

    on<ChessGameInit>(_onInit);
    on<SquareTappedEvent>(_onSquareTapped);
  }

  @override
  Future<void> close() {
    player.dispose();

    return super.close();
  }

  void _onInit(ChessGameInit event, Emitter<ChessGameState> emit) {
    final position = GamePosition(
      board: ChessUtils.readGameState(event.initGameState),
    );

    emit(
      const ChessGameState().copyWith(
        isLoading: false,
        currentState: 0,
        gameStates: {0: position},
        status: ChessRules.status(position),
      ),
    );
  }

  void _onSquareTapped(SquareTappedEvent event, Emitter<ChessGameState> emit) {
    if (state.isLoading || state.isGameOver) return;

    final position = state.position;
    final piece = position.board[event.index];
    final isOwnPiece =
        piece.isNotEmpty && ChessRules.isWhite(piece) == position.whiteToMove;

    if (isOwnPiece) {
      _selectChess(event.index, emit);
    } else if (state.selectedChess != null &&
        state.hintMoves.contains(event.index)) {
      _moveTo(event.index, emit);
    } else if (state.selectedChess != null) {
      player.play(AssetSource(ChessSounds.illegal), volume: 1);
    }
  }

  void _selectChess(int index, Emitter<ChessGameState> emit) {
    player.play(AssetSource(ChessSounds.click), volume: 0.5);

    if (state.selectedChess == index) {
      emit(
        state.copyWith(isClearSelected: true, hintMoves: [], hightLights: []),
      );
    } else {
      emit(
        state.copyWith(
          selectedChess: index,
          hintMoves: ChessRules.legalMoves(state.position, index),
          hightLights: [index],
        ),
      );
    }
  }

  void _moveTo(int index, Emitter<ChessGameState> emit) {
    final from = state.selectedChess!;
    final result = ChessRules.applyMove(state.position, from, index);
    final status = ChessRules.status(result.position);

    player.play(AssetSource(_moveSound(result, status)), volume: 1);

    final Map<int, GamePosition> gameHistory = Map.from(state.gameStates);
    gameHistory.addAll({state.gameStates.length: result.position});

    emit(
      state.copyWith(
        currentState: gameHistory.length - 1,
        gameStates: gameHistory,
        status: status,
        hintMoves: [],
        hightLights: [index, from],
        isClearSelected: true,
      ),
    );
  }

  String _moveSound(MoveResult result, GameStatus status) {
    switch (status) {
      case GameStatus.checkmate:
      case GameStatus.stalemate:
        return ChessSounds.gameEnd;
      case GameStatus.check:
        return ChessSounds.moveCheck;
      case GameStatus.playing:
        if (result.isPromotion) return ChessSounds.promote;
        if (result.isCastle) return ChessSounds.castle;
        if (result.isCapture) return ChessSounds.capture;
        return ChessSounds.moveSelf;
    }
  }
}
