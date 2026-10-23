import 'package:chess/app.dart';
import 'package:chess/features/game/models/chess_factory.dart';
import 'package:flutter/material.dart';

void main() {
  Chess().initChess();
  runApp(const ChessApp());
}
