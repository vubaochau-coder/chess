import 'package:chess/features/game/models/black_chess_model.dart';
import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class BlackQueenModel extends BlackChess {
  BlackQueenModel() : super(type: ChessType.queen);

  @override
  String toText() {
    return 'q';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackQueen(size: size ?? this.size);
  }
}
