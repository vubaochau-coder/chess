import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/abstract/black_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class BlackPawnModel extends BlackChess {
  BlackPawnModel(Position p) : super(position: p, type: ChessType.pawn);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  List<Position> getPossibleMove() {
    List<Position> possibleMoves = [];
    if (position.x == 7) return possibleMoves;

    possibleMoves.add(Position(x: position.x + 1, y: position.y));
    if (position.x == 1) {
      possibleMoves.add(Position(x: position.x + 2, y: position.y));
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
