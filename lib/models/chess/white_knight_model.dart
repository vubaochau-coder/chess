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
