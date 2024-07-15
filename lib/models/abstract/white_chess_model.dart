import 'chess_model.dart';

abstract class WhiteChess extends Chess {
  WhiteChess({required super.type, required super.position}) : super(team: 0);
}
