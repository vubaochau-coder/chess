import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/abstract/white_chess_model.dart';
import 'package:flutter/material.dart';
import '../position_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class WhiteRookModel extends WhiteChess {
  WhiteRookModel() : super(type: ChessType.rook);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  List<Position> getPossibleMove(Position position, List<String> gameState) {
    List<Position> possibleMoves = [];

    return possibleMoves;
  }

  @override
  String toText() {
    return 'R';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteRook(
      size: size ?? this.size,
    );
  }
}
