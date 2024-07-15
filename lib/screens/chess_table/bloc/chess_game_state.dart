part of 'chess_game_bloc.dart';

class ChessGameState extends Equatable {
  final bool isLoading;
  final int currentState;
  final Map<int, String> gameStates;
  final int? selectedChess;
  final List<int> hintMoves;
  final List<int> hightLights;

  const ChessGameState({
    this.isLoading = true,
    this.currentState = 0,
    this.gameStates = const {},
    this.selectedChess,
    this.hintMoves = const [],
    this.hightLights = const [],
  });

  @override
  List<Object?> get props => [
        isLoading,
        currentState,
        gameStates,
        selectedChess,
        hintMoves,
        hightLights
      ];

  ChessGameState copyWith({
    bool? isLoading,
    int? currentState,
    Map<int, String>? gameStates,
    int? selectedChess,
    bool isClearSelected = false,
    List<int>? hintMoves,
    List<int>? hightLights,
  }) {
    return ChessGameState(
      isLoading: isLoading ?? this.isLoading,
      currentState: currentState ?? this.currentState,
      gameStates: gameStates ?? this.gameStates,
      selectedChess:
          isClearSelected ? null : selectedChess ?? this.selectedChess,
      hintMoves: hintMoves ?? this.hintMoves,
      hightLights: hightLights ?? this.hightLights,
    );
  }
}
