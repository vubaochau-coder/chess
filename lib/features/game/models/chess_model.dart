import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/position_model.dart';
import 'package:chess/features/game/models/chess_type.dart';
import 'package:flutter/material.dart';

abstract class ChessModel {
  final ChessType type;
  final int team;
  final double size;

  ChessModel({required this.team, required this.type, this.size = 34});

  // Nước đi theo cách di chuyển của quân, chưa xét vua bị chiếu.
  // Nước đi hợp lệ đầy đủ dùng ChessRules.legalMoves.
  List<Position> getPossibleMove(Position position, List<String> gameState) {
    return ChessRules.pseudoMoves(
      gameState,
      position.toIndex(),
    ).map(Position.fromIndex).toList();
  }

  String toText();

  Widget draw(BuildContext context, double? size);
}
