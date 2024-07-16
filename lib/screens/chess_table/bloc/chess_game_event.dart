part of 'chess_game_bloc.dart';

class ChessGameEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChessGameInit extends ChessGameEvent {
  final String initGameState;

  ChessGameInit({required this.initGameState});
}

class ChessSelectedEvent extends ChessGameEvent {
  final int index;
  final List<Position> hintMoves;

  ChessSelectedEvent({required this.index, required this.hintMoves});
}

class MoveChessToEvent extends ChessGameEvent {
  final int index;

  MoveChessToEvent({required this.index});
}
