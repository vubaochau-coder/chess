import 'package:chess/models/abstract/white_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import '../../enums/chess_type.dart';

class WhiteKingModel extends WhiteChess {
  WhiteKingModel(Position p) : super(position: p, type: ChessType.king);

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
    return 'K';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteKing(
      size: size ?? this.size,
    );
  }
}
