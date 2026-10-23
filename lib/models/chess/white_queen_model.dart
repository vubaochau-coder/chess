import 'package:chess/models/abstract/white_chess_model.dart';
import 'package:flutter/material.dart';

import '../../enums/chess_type.dart';
import '../position_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;

class WhiteQueenModel extends WhiteChess {
  WhiteQueenModel() : super(type: ChessType.queen);

  @override
  bool canMoveTo(Position target) {
    return false;
  }

  @override
  String toText() {
    return 'Q';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteQueen(
      size: size ?? this.size,
    );
  }
}
