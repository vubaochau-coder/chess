import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/abstract/black_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class BlackKnightModel extends BlackChess {
  BlackKnightModel() : super(type: ChessType.king);

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
    return 'n';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackKnight(
      size: size ?? this.size,
    );
  }
}
