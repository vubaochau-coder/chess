import 'package:chess/themes/colors.dart';
import 'package:flutter/material.dart';

class GameHintPainter extends CustomPainter {
  final double cellSize;
  final List<int> hints;
  final List<int> hightLight;

  GameHintPainter({
    super.repaint,
    required this.cellSize,
    required this.hints,
    required this.hightLight,
  });

  final darkSelectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.darkSquareSelected;

  final lightSelectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.lightSquareSelected;

  final hintPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.squareAvailable;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index in hightLight) {
      final row = index ~/ 8;
      final col = index % 8;

      final paint = _createPaint((row + col) % 2 == 1);
      canvas.drawRect(
        Rect.fromLTRB(
          col * cellSize,
          row * cellSize,
          (col + 1) * cellSize,
          (row + 1) * cellSize,
        ),
        paint,
      );
    }

    for (var index in hints) {
      final row = index ~/ 8;
      final col = index % 8;

      canvas.drawCircle(
        Offset(
          col * cellSize + cellSize / 2,
          row * cellSize + cellSize / 2,
        ),
        4,
        hintPaint,
      );
    }
  }

  Paint _createPaint(bool isDark) {
    return isDark ? darkSelectPaint : lightSelectPaint;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
