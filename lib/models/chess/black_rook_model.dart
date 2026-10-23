import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/abstract/black_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class BlackRookModel extends BlackChess {
  BlackRookModel() : super(type: ChessType.rook);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  String toText() {
    return 'r';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackRook(
      size: size ?? this.size,
    );
  }
}
