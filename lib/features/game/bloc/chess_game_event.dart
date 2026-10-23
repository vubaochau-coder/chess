part of 'chess_game_bloc.dart';

class ChessGameEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChessGameInit extends ChessGameEvent {
  final String initGameState;

  ChessGameInit({required this.initGameState});
}

class SquareTappedEvent extends ChessGameEvent {
  final int index;

  SquareTappedEvent({required this.index});
}
