import 'package:chess/theme/colors.dart';
import 'package:flutter/material.dart';

class GameBoardPainter extends CustomPainter {
  final double cellSize;

  GameBoardPainter({required this.cellSize});

  final darkPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.darkSquare;

  final lightPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.lightSquare;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw game table
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        final bool isDark = (j + i) % 2 == 1;

        final paint = _createPaint(isDark);
        canvas.drawRect(
          Rect.fromLTRB(
            j * cellSize,
            i * cellSize,
            (j + 1) * cellSize,
            (i + 1) * cellSize,
          ),
          paint,
        );
      }
    }
  }

  Paint _createPaint(bool isDark) {
    return isDark ? darkPaint : lightPaint;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
