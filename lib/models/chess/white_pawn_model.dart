import 'package:chess/enums/chess_type.dart';
import '../abstract/white_chess_model.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class WhitePawnModel extends WhiteChess {
  WhitePawnModel() : super(type: ChessType.pawn);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  String toText() {
    return 'P';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhitePawn(
      size: size ?? this.size,
    );
  }
}
