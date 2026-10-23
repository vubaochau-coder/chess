import 'package:chess/features/game/models/black_chess_model.dart';
import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class BlackRookModel extends BlackChess {
  BlackRookModel() : super(type: ChessType.rook);

  @override
  String toText() {
    return 'r';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackRook(size: size ?? this.size);
  }
}
