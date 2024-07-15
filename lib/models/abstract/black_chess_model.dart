import 'chess_model.dart';

abstract class BlackChess extends Chess {
  BlackChess({required super.position, required super.type}) : super(team: 1);
}
