import 'package:chess/theme/colors.dart';
import 'package:flutter/rendering.dart';

/// Vẽ 64 ô bàn cờ. Không phụ thuộc state nên không bao giờ cần vẽ lại
/// (kích thước đổi thì Flutter tự gọi paint lại).
class BoardPainter extends CustomPainter {
  const BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final light = Paint()..color = ChessColors.lightSquare;
    final dark = Paint()..color = ChessColors.darkSquare;

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
  bool shouldRepaint(BoardPainter oldDelegate) => false;
}
