import 'package:chess/features/game/models/black_chess_model.dart';
import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class BlackPawnModel extends BlackChess {
  BlackPawnModel() : super(type: ChessType.pawn);

  @override
  String toText() {
    return 'p';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackPawn(size: size ?? this.size);
  }
}
