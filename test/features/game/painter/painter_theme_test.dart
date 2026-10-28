import 'package:chess/features/game/painter/board_painter.dart';
import 'package:chess/features/game/painter/highlight_painter.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Painter theme shouldRepaint', () {
    test('BoardPainter shouldRepaint compares colors', () {
      final p1 = BoardPainter(BoardTheme.wood.colors);
      final p2 = BoardPainter(BoardTheme.wood.colors);
      final p3 = BoardPainter(BoardTheme.green.colors);

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });

    test('HighlightPainter shouldRepaint compares colors', () {
      final p1 = HighlightPainter(
        colors: BoardTheme.wood.colors,
        highlighted: const [0],
        targets: const [1],
        checkSquare: null,
      );
      final p2 = HighlightPainter(
        colors: BoardTheme.wood.colors,
        highlighted: const [0],
        targets: const [1],
        checkSquare: null,
      );
      final p3 = HighlightPainter(
        colors: BoardTheme.green.colors,
        highlighted: const [0],
        targets: const [1],
        checkSquare: null,
      );

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });
  });
}
