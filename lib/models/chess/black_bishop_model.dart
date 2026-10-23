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
