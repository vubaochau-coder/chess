import 'package:chess/theme/board_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardColors and BoardTheme', () {
    test('has exactly 5 themes with correct labels', () {
      expect(BoardTheme.values.length, 5);
      expect(BoardTheme.wood.label, 'Gỗ');
      expect(BoardTheme.green.label, 'Xanh lá');
      expect(BoardTheme.blue.label, 'Xanh dương');
      expect(BoardTheme.gray.label, 'Xám');
      expect(BoardTheme.purple.label, 'Tím');
    });

    test('wood theme has correct color values', () {
      final colors = BoardTheme.wood.colors;
      expect(colors.lightSquare, const Color(0xFFF2E1C3));
      expect(colors.darkSquare, const Color(0xFFC3A082));
      expect(colors.lightSelected, const Color(0xFFF9F07B));
      expect(colors.darkSelected, const Color(0xFFE2CF57));
      expect(colors.hint, const Color(0xFF80361B));
      expect(colors.check, const Color(0xCCE53935));
    });

    test('green theme has correct color values', () {
      final colors = BoardTheme.green.colors;
      expect(colors.lightSquare, const Color(0xFFEEEED2));
      expect(colors.darkSquare, const Color(0xFF769656));
      expect(colors.lightSelected, const Color(0xFFF6F669));
      expect(colors.darkSelected, const Color(0xFFBACA2B));
      expect(colors.hint, const Color(0x59000000));
      expect(colors.check, const Color(0xCCE53935));
    });

    test('blue theme has correct color values', () {
      final colors = BoardTheme.blue.colors;
      expect(colors.lightSquare, const Color(0xFFDEE3E6));
      expect(colors.darkSquare, const Color(0xFF8CA2AD));
      expect(colors.lightSelected, const Color(0xFFE5EB9B));
      expect(colors.darkSelected, const Color(0xFFB8C46A));
      expect(colors.hint, const Color(0x59000000));
      expect(colors.check, const Color(0xCCE53935));
    });

    test('gray theme has correct color values', () {
      final colors = BoardTheme.gray.colors;
      expect(colors.lightSquare, const Color(0xFFE8E8E8));
      expect(colors.darkSquare, const Color(0xFFA0A0A0));
      expect(colors.lightSelected, const Color(0xFFF5F682));
      expect(colors.darkSelected, const Color(0xFFB9CA43));
      expect(colors.hint, const Color(0x59000000));
      expect(colors.check, const Color(0xCCE53935));
    });

    test('purple theme has correct color values', () {
      final colors = BoardTheme.purple.colors;
      expect(colors.lightSquare, const Color(0xFFEDE4F7));
      expect(colors.darkSquare, const Color(0xFF9F86C0));
      expect(colors.lightSelected, const Color(0xFFF5F682));
      expect(colors.darkSelected, const Color(0xFFC8B95A));
      expect(colors.hint, const Color(0x59000000));
      expect(colors.check, const Color(0xCCE53935));
    });

    test('BoardColors equality and hashCode', () {
      final c1 = BoardTheme.wood.colors;
      const c2 = BoardColors(
        lightSquare: Color(0xFFF2E1C3),
        darkSquare: Color(0xFFC3A082),
        lightSelected: Color(0xFFF9F07B),
        darkSelected: Color(0xFFE2CF57),
        hint: Color(0xFF80361B),
        check: Color(0xCCE53935),
      );
      final c3 = BoardTheme.green.colors;

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('BoardTheme.fromName parses correctly and defaults to wood', () {
      expect(BoardTheme.fromName('green'), BoardTheme.green);
      expect(BoardTheme.fromName('blue'), BoardTheme.blue);
      expect(BoardTheme.fromName('gray'), BoardTheme.gray);
      expect(BoardTheme.fromName('purple'), BoardTheme.purple);
      expect(BoardTheme.fromName('wood'), BoardTheme.wood);
      expect(BoardTheme.fromName('invalid'), BoardTheme.wood);
      expect(BoardTheme.fromName(null), BoardTheme.wood);
    });
  });
}
