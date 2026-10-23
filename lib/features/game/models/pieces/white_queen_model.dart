import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess/features/game/models/white_chess_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class WhiteQueenModel extends WhiteChess {
  WhiteQueenModel() : super(type: ChessType.queen);

  @override
  String toText() {
    return 'Q';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteQueen(size: size ?? this.size);
  }
}
