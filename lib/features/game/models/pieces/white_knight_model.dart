import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess/features/game/models/white_chess_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class WhiteKnightModel extends WhiteChess {
  WhiteKnightModel() : super(type: ChessType.knight);

  @override
  String toText() {
    return 'N';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteKnight(size: size ?? this.size);
  }
}
