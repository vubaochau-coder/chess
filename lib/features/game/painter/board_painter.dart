import 'package:chess/theme/board_theme.dart';
import 'package:flutter/rendering.dart';

/// Vẽ 64 ô bàn cờ theo [BoardColors].
class BoardPainter extends CustomPainter {
  const BoardPainter(this.colors);

  final BoardColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final light = Paint()..color = colors.lightSquare;
    final dark = Paint()..color = colors.darkSquare;

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, cell, cell),
          (row + col).isOdd ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => colors != oldDelegate.colors;
}
