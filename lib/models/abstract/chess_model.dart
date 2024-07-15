import 'package:chess/enums/chess_type.dart';
import 'package:chess/models/position_model.dart';
import 'package:flutter/material.dart';

abstract class Chess {
  final Position position;
  final ChessType type;
  final int team;
  final double size;

  Chess({
    required this.team,
    required this.type,
    required this.position,
    this.size = 30,
  });

  bool canMoveTo(Position target);

  List<Position> getPossibleMove();

  String toText();

  Widget draw(BuildContext context, double? size);
}
