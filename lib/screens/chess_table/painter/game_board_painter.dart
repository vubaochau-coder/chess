import 'package:chess/themes/colors.dart';
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
    print('VBC repaint board');
    print('VBC: size ${size.hashCode}');
    print('VBC: cellSize ${cellSize.hashCode}');
    print('VBC: canvas ${canvas.hashCode}');

    // Draw game table
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        bool isDark = (j + i) % 2 == 1;

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
    print('VBC shouldRepaint');
    print('VBC: ${oldDelegate}');

    return false;
  }
}
