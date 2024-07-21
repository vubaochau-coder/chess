import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/abstract/black_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class BlackBishopModel extends BlackChess {
  BlackBishopModel() : super(type: ChessType.bishop);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  List<Position> getPossibleMove(Position position, List<String> gameState) {
    List<Position> possibleMoves = [];

    // Directions the bishop can move: top-right, top-left, bottom-right, bottom-left
    List<Position> directions = [
      Position(x: 1, y: 1),
      Position(x: 1, y: -1),
      Position(x: -1, y: 1),
      Position(x: -1, y: -1),
    ];

    for (var direction in directions) {
      int newX = position.x;
      int newY = position.y;

      while (true) {
        newX += direction.x;
        newY += direction.y;

        if (newX >= 0 && newX < 8 && newY >= 0 && newY < 8) {
          final targetSqare = Position(x: newX, y: newY);
          if (gameState[targetSqare.toIndex()].isNotEmpty) {
            break;
          }

          possibleMoves.add(targetSqare);
        } else {
          break;
        }
      }
    }

    return possibleMoves;
  }

  @override
  String toText() {
    return 'b';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackBishop(
      size: size ?? this.size,
    );
  }
}
