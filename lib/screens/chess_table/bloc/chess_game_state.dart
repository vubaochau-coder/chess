part of 'chess_game_bloc.dart';

class ChessGameState extends Equatable {
  final bool isLoading;
  final int currentState;
  final Map<int, GamePosition> gameStates;
  final GameStatus status;
  final int? selectedChess;
  final List<int> hintMoves;
  final List<int> hightLights;

  const ChessGameState({
    this.isLoading = true,
    this.currentState = 0,
    this.gameStates = const {},
    this.status = GameStatus.playing,
    this.selectedChess,
    this.hintMoves = const [],
    this.hightLights = const [],
  });

  GamePosition get position => gameStates[currentState]!;

  bool get isGameOver =>
      status == GameStatus.checkmate || status == GameStatus.stalemate;

  @override
  List<Object?> get props => [
        isLoading,
        currentState,
        gameStates,
        status,
        selectedChess,
        hintMoves,
        hightLights
      ];

  ChessGameState copyWith({
    bool? isLoading,
    int? currentState,
    Map<int, GamePosition>? gameStates,
    GameStatus? status,
    int? selectedChess,
    bool isClearSelected = false,
    List<int>? hintMoves,
    List<int>? hightLights,
  }) {
    return ChessGameState(
      isLoading: isLoading ?? this.isLoading,
      currentState: currentState ?? this.currentState,
      gameStates: gameStates ?? this.gameStates,
      status: status ?? this.status,
      selectedChess:
          isClearSelected ? null : selectedChess ?? this.selectedChess,
      hintMoves: hintMoves ?? this.hintMoves,
      hightLights: hightLights ?? this.hightLights,
    );
  }
}
