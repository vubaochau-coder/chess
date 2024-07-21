import 'chess_model.dart';

abstract class BlackChess extends ChessModel {
  BlackChess({required super.type}) : super(team: 1);
}
