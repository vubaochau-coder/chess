import 'package:chess/features/game/models/black_chess_model.dart';
import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class BlackKingModel extends BlackChess {
  BlackKingModel() : super(type: ChessType.king);

  @override
  String toText() {
    return 'k';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackKing(size: size ?? this.size);
  }
}
