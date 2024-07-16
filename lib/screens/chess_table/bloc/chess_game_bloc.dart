import 'package:bloc/bloc.dart';
import 'package:chess/utils/chess_utils.dart';
import 'package:equatable/equatable.dart';

import '../../../models/position_model.dart';

part 'chess_game_event.dart';
part 'chess_game_state.dart';

class ChessGameBloc extends Bloc<ChessGameEvent, ChessGameState> {
  ChessGameBloc() : super(const ChessGameState()) {
    on<ChessGameInit>(_onInit);
    on<ChessSelectedEvent>(_onChessSelected);
    on<MoveChessToEvent>(_onMoveTo);
  }

  _onInit(ChessGameInit event, Emitter emit) {
    Map<int, List<String>> initState = {};

    List<String> gameState = ChessUtils.readGameState(event.initGameState);
    initState[0] = gameState;

    emit(state.copyWith(
      isLoading: false,
      currentState: 0,
      gameStates: initState,
    ));
  }

  _onChessSelected(ChessSelectedEvent event, Emitter emit) {
    if (state.selectedChess == event.index) {
      emit(
        state.copyWith(
          isClearSelected: true,
          hintMoves: [],
          hightLights: [],
        ),
      );
    } else {
      List<int> hint = [];
      for (var position in event.hintMoves) {
        hint.add(position.toIndex());
      }

      emit(
        state.copyWith(
          selectedChess: event.index,
          hintMoves: hint,
          hightLights: [event.index],
        ),
      );
    }
  }

  _onMoveTo(MoveChessToEvent event, Emitter emit) {
    if (state.hintMoves.contains(event.index)) {
      // Get current chess
      List<String> currentChess = state.gameStates[state.currentState]!;
      String selectedChess = currentChess[state.selectedChess!];

      List<String> newChess = List.from(currentChess);
      newChess[state.selectedChess!] = '';
      newChess[event.index] = selectedChess;

      Map<int, List<String>> gameHistory = Map.from(state.gameStates);
      gameHistory.addAll({state.gameStates.length: newChess});

      emit(
        state.copyWith(
          currentState: gameHistory.length - 1,
          gameStates: gameHistory,
          hintMoves: [],
          hightLights: [event.index, state.selectedChess!],
          isClearSelected: true,
        ),
      );
    }
  }
}
