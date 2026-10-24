import 'package:chess/theme/board_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Vẽ các lớp tô màu trên bàn cờ: nước vừa đi, quân đang chọn, vua bị chiếu
/// và chấm gợi ý nước đi.
class HighlightPainter extends CustomPainter {
  const HighlightPainter({
    required this.colors,
    required this.highlighted,
    required this.targets,
    required this.checkSquare,
    this.flipped = false,
  });

  final BoardColors colors;

  /// Ô được tô vàng (quân đang chọn, ô đi và ô đến của nước vừa đi).
  final List<int> highlighted;
  final List<int> targets;
  final int? checkSquare;
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final lightSelected = Paint()..color = colors.lightSelected;
    final darkSelected = Paint()..color = colors.darkSelected;

    int displaySquare(int sq) => flipped ? (63 - sq) : sq;

    Rect rectOf(int square) {
      final ds = displaySquare(square);
      return Rect.fromLTWH(ds % 8 * cell, ds ~/ 8 * cell, cell, cell);
    }

    for (final square in highlighted) {
      final isDark = (square ~/ 8 + square % 8).isOdd;
      canvas.drawRect(rectOf(square), isDark ? darkSelected : lightSelected);
    }

    if (checkSquare case final square?) {
      canvas.drawRect(rectOf(square), Paint()..color = colors.check);
    }

    final hint = Paint()..color = colors.hint;
    for (final square in targets) {
      canvas.drawCircle(rectOf(square).center, cell * 0.1, hint);
    }
  }

  @override
  bool shouldRepaint(HighlightPainter oldDelegate) {
    return colors != oldDelegate.colors ||
        !listEquals(highlighted, oldDelegate.highlighted) ||
        !listEquals(targets, oldDelegate.targets) ||
        checkSquare != oldDelegate.checkSquare ||
        flipped != oldDelegate.flipped;
  }
}
