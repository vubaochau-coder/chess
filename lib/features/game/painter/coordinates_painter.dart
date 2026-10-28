import 'package:chess/theme/board_theme.dart';
import 'package:flutter/rendering.dart';

/// Vẽ tọa độ trong các ô sát mép: số hàng `1–8` ở góc trên-trái cột trái cùng,
/// chữ cột `a–h` ở góc dưới-phải hàng dưới cùng. Màu chữ tương phản với ô.
class CoordinatesPainter extends CustomPainter {
  const CoordinatesPainter({required this.colors, this.flipped = false});

  final BoardColors colors;
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final pad = cell * 0.06;

    for (var i = 0; i < 8; i++) {
      final rank = flipped ? i + 1 : 8 - i;
      final rankLabel = _layout('$rank', cell, _labelColor(i, 0));
      rankLabel.paint(canvas, Offset(pad, i * cell + pad * 0.5));
      rankLabel.dispose();

      final file = String.fromCharCode(97 + (flipped ? 7 - i : i));
      final fileLabel = _layout(file, cell, _labelColor(7, i));
      fileLabel.paint(
        canvas,
        Offset(
          (i + 1) * cell - fileLabel.width - pad,
          8 * cell - fileLabel.height - pad * 0.3,
        ),
      );
      fileLabel.dispose();
    }
  }

  /// Màu chữ trên ô hiển thị ([row], [col]): tương phản với màu ô.
  Color _labelColor(int row, int col) =>
      (row + col).isOdd ? colors.lightSquare : colors.darkSquare;

  TextPainter _layout(String text, double cell, Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: cell * 0.18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(CoordinatesPainter oldDelegate) =>
      colors != oldDelegate.colors || flipped != oldDelegate.flipped;
}
