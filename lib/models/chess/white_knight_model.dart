import 'package:chess/models/abstract/white_chess_model.dart';
import 'package:flutter/material.dart';

import '../../enums/chess_type.dart';
import '../position_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class WhiteKnightModel extends WhiteChess {
  WhiteKnightModel() : super(type: ChessType.knight);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  List<Position> getPossibleMove(Position position, List<String> gameState) {
    List<Position> possibleMoves = [];

    // List of all possible knight moves (x, y) offsets
    List<Position> moves = [
      Position(x: 2, y: 1),
      Position(x: 2, y: -1),
      Position(x: -2, y: 1),
      Position(x: -2, y: -1),
      Position(x: 1, y: 2),
      Position(x: 1, y: -2),
      Position(x: -1, y: 2),
      Position(x: -1, y: -2),
    ];

    for (var move in moves) {
      int newX = position.x + move.x;
      int newY = position.y + move.y;
      if (newX >= 0 && newX < 8 && newY >= 0 && newY < 8) {
        possibleMoves.add(Position(x: newX, y: newY));
      }
    }

    return possibleMoves;
  }

  @override
  String toText() {
    return 'N';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteKnight(
      size: size ?? this.size,
    );
  }
}
