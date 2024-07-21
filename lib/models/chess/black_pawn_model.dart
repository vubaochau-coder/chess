import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/abstract/black_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class BlackPawnModel extends BlackChess {
  BlackPawnModel() : super(type: ChessType.pawn);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  List<Position> getPossibleMove(Position position, List<String> gameState) {
    List<Position> possibleMoves = [];
    if (position.x == 7) return possibleMoves;

    final sqr1 = Position(x: position.x + 1, y: position.y);
    if (gameState[sqr1.toIndex()].isEmpty) {
      possibleMoves.add(sqr1);

      if (position.x == 1) {
        final sqr2 = Position(x: position.x + 2, y: position.y);
        if (gameState[sqr2.toIndex()].isEmpty) {
          possibleMoves.add(sqr2);
        }
      }
    }

    return possibleMoves;
  }

  @override
  String toText() {
    return 'p';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackPawn(
      size: size ?? this.size,
    );
  }
}
