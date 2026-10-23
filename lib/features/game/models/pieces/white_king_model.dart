import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess/features/game/models/white_chess_model.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class WhiteKingModel extends WhiteChess {
  WhiteKingModel() : super(type: ChessType.king);

  @override
  String toText() {
    return 'K';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.WhiteKing(size: size ?? this.size);
  }
}
