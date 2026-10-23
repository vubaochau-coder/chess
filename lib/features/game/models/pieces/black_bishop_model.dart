import 'package:chess/features/game/models/black_chess_model.dart';
import 'package:chess/features/game/models/chess_type.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart' as vector;
import 'package:flutter/material.dart';

class BlackBishopModel extends BlackChess {
  BlackBishopModel() : super(type: ChessType.bishop);

  @override
  String toText() {
    return 'b';
  }

  @override
  Widget draw(BuildContext context, double? size) {
    return vector.BlackBishop(size: size ?? this.size);
  }
}
