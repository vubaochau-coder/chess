import 'package:chess/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('dark theme uses the classic dark palette', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFC8A15A));
      expect(theme.colorScheme.surface, const Color(0xFF17110D));
      expect(theme.colorScheme.tertiary, const Color(0xFFC8A15A));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF17110D));
    });

    test('light theme matches the logo and splash palette', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF2A1E16));
      expect(theme.colorScheme.surface, const Color(0xFFF2E1C3));
      expect(theme.colorScheme.tertiary, const Color(0xFF855A38));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF2E1C3));
    });

    test('headlines and app bar titles use the serif family', () {
      final theme = AppTheme.dark();

      expect(theme.textTheme.displaySmall?.fontFamily, AppTheme.serifFamily);
      expect(
        theme.appBarTheme.titleTextStyle?.fontFamily,
        AppTheme.serifFamily,
      );
    });
  });
}
