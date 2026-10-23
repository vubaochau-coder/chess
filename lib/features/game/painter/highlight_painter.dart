import 'package:chess/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Vẽ các lớp tô màu trên bàn cờ: nước vừa đi, quân đang chọn, vua bị chiếu
/// và chấm gợi ý nước đi.
class HighlightPainter extends CustomPainter {
  const HighlightPainter({
    required this.highlighted,
    required this.targets,
    required this.checkSquare,
  });

  /// Ô được tô vàng (quân đang chọn, ô đi và ô đến của nước vừa đi).
  final List<int> highlighted;
  final List<int> targets;
  final int? checkSquare;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 8;
    final lightSelected = Paint()..color = ChessColors.lightSquareSelected;
    final darkSelected = Paint()..color = ChessColors.darkSquareSelected;

    Rect rectOf(int square) =>
        Rect.fromLTWH(square % 8 * cell, square ~/ 8 * cell, cell, cell);

    for (final square in highlighted) {
      final isDark = (square ~/ 8 + square % 8).isOdd;
      canvas.drawRect(rectOf(square), isDark ? darkSelected : lightSelected);
    }

    if (checkSquare case final square?) {
      canvas.drawRect(rectOf(square), Paint()..color = ChessColors.squareCheck);
    }

    final hint = Paint()..color = ChessColors.squareAvailable;
    for (final square in targets) {
      canvas.drawCircle(rectOf(square).center, cell * 0.1, hint);
    }
  }

  @override
  bool shouldRepaint(HighlightPainter oldDelegate) {
    return !listEquals(highlighted, oldDelegate.highlighted) ||
        !listEquals(targets, oldDelegate.targets) ||
        checkSquare != oldDelegate.checkSquare;
  }
}
