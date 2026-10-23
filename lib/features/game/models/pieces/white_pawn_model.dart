import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess/features/game/models/white_chess_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class WhitePawnModel extends WhiteChess {
  WhitePawnModel() : super(type: ChessType.pawn);

  @override
  String toText() {
    return 'P';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhitePawn(size: size ?? this.size);
  }
}
