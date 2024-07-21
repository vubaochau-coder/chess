import 'package:chess/themes/colors.dart';
import 'package:flutter/material.dart';

class GameBoardPainter extends CustomPainter {
  final double cellSize;
  final List<int> hints;
  final List<int> hightLight;

  GameBoardPainter({
    required this.cellSize,
    required this.hints,
    required this.hightLight,
  });

  final darkPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.darkSquare;

  final darkSelectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.darkSquareSelected;

  final lightPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.lightSquare;

  final lightSelectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.lightSquareSelected;

  final hintPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = ChessColors.squareAvailable;

  @override
  void paint(Canvas canvas, Size size) {
    List<int> currentSelects = List.from(hightLight);
    List<int> currentHints = List.from(hints);

    // Draw game table
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        int currentIndex = i * 8 + j;
        bool isDark = (j + i) % 2 == 1;
        bool isSelect = currentSelects.remove(currentIndex);
        bool isHint = currentHints.remove(currentIndex);

        final paint = _createPaint(isDark, isSelect);
        canvas.drawRect(
          Rect.fromLTRB(
            j * cellSize,
            i * cellSize,
            (j + 1) * cellSize,
            (i + 1) * cellSize,
          ),
          paint,
        );

        if (isHint) {
          canvas.drawCircle(
            Offset(
              j * cellSize + cellSize / 2,
              i * cellSize + cellSize / 2,
            ),
            4,
            hintPaint,
          );
        }
      }
    }
  }

  Paint _createPaint(bool isDark, bool isSelect) {
    if (isSelect) {
      return isDark ? darkSelectPaint : lightSelectPaint;
    }
    return isDark ? darkPaint : lightPaint;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
