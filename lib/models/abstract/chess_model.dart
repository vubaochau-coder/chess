import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';

abstract class ChessModel {
  final ChessType type;
  final int team;
  final double size;

  ChessModel({
    required this.team,
    required this.type,
    this.size = 34,
  });

  bool canMoveTo(Position target);

  List<Position> getPossibleMove(Position position, List<String> gameState);

  String toText();

  Widget draw(BuildContext context, double? size);
}
