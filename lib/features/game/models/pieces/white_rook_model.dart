import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess/features/game/models/white_chess_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class WhiteRookModel extends WhiteChess {
  WhiteRookModel() : super(type: ChessType.rook);

  @override
  String toText() {
    return 'R';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteRook(size: size ?? this.size);
  }
}
