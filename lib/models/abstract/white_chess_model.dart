import 'chess_model.dart';

abstract class WhiteChess extends ChessModel {
  WhiteChess({required super.type}) : super(team: 0);
}
