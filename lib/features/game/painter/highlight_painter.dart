import 'package:chess/theme/board_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Vẽ các lớp tô màu trên bàn cờ: nước vừa đi, quân đang chọn, vua bị chiếu,
/// chấm nước đi hợp lệ và nước gợi ý (tô ô + mũi tên).
class HighlightPainter extends CustomPainter {
  const HighlightPainter({
    required this.colors,
    required this.highlighted,
    required this.targets,
    required this.checkSquare,
    this.flipped = false,
    this.suggestion,
  });

  /// Màu nước gợi ý: cố định (không theo theme bàn cờ) để luôn khác màu tô nước
  /// vừa đi và nổi trên mọi theme.
  static const suggestionColor = Color(0xCC2F80ED);

  final BoardColors colors;

  /// Ô được tô vàng (quân đang chọn, ô đi và ô đến của nước vừa đi).
  final List<int> highlighted;
  final List<int> targets;
  final int? checkSquare;
  final bool flipped;

  /// Nước gợi ý (ô đi, ô đến), null nếu không có.
  final ({int from, int to})? suggestion;

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

    if (suggestion case (:final from, :final to)) {
      final tint = Paint()..color = suggestionColor.withValues(alpha: 0.3);
      canvas
        ..drawRect(rectOf(from), tint)
        ..drawRect(rectOf(to), tint);
      _drawArrow(canvas, rectOf(from).center, rectOf(to).center, cell);
    }

    final hint = Paint()..color = colors.hint;
    for (final square in targets) {
      canvas.drawCircle(rectOf(square).center, cell * 0.1, hint);
    }
  }

  static void _drawArrow(Canvas canvas, Offset start, Offset end, double cell) {
    final delta = end - start;
    final length = delta.distance;
    if (length == 0) return;
    final dir = delta / length;
    final normal = Offset(-dir.dy, dir.dx);
    final headLength = cell * 0.4;
    final headWidth = cell * 0.36;
    // Đầu mũi tên dừng trước tâm ô đích một chút để không che hết quân.
    final tip = end - dir * (cell * 0.12);
    final base = tip - dir * headLength;

    final paint = Paint()..color = suggestionColor;
    canvas
      ..drawLine(
        start,
        base,
        paint
          ..strokeWidth = cell * 0.16
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(
            base.dx + normal.dx * headWidth,
            base.dy + normal.dy * headWidth,
          )
          ..lineTo(
            base.dx - normal.dx * headWidth,
            base.dy - normal.dy * headWidth,
          )
          ..close(),
        Paint()..color = suggestionColor,
      );
  }

  @override
  bool shouldRepaint(HighlightPainter oldDelegate) {
    return colors != oldDelegate.colors ||
        !listEquals(highlighted, oldDelegate.highlighted) ||
        !listEquals(targets, oldDelegate.targets) ||
        checkSquare != oldDelegate.checkSquare ||
        suggestion != oldDelegate.suggestion ||
        flipped != oldDelegate.flipped;
  }
}
