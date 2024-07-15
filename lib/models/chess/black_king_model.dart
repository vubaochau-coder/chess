import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/abstract/black_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class BlackKingModel extends BlackChess {
  BlackKingModel(Position p) : super(position: p, type: ChessType.king);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  List<Position> getPossibleMove() {
    List<Position> possibleMoves = [];

    return possibleMoves;
  }

  @override
  String toText() {
    return 'k';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackKing(
      size: size ?? this.size,
    );
  }
}
