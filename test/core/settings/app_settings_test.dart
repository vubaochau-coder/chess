import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test(
      'default constructor sets themeMode to system and boardTheme to wood',
      () {
        const settings = AppSettings();
        expect(settings.themeMode, AppThemeMode.system);
        expect(settings.boardTheme, BoardTheme.wood);
      },
    );

    test('copyWith updates themeMode and boardTheme', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        themeMode: AppThemeMode.dark,
        boardTheme: BoardTheme.green,
      );
      expect(updated.themeMode, AppThemeMode.dark);
      expect(updated.boardTheme, BoardTheme.green);

      final untouched = updated.copyWith();
      expect(untouched.themeMode, AppThemeMode.dark);
      expect(untouched.boardTheme, BoardTheme.green);
    });

    test('props contains themeMode and boardTheme', () {
      const s1 = AppSettings(
        themeMode: AppThemeMode.light,
        boardTheme: BoardTheme.blue,
      );
      const s2 = AppSettings(
        themeMode: AppThemeMode.light,
        boardTheme: BoardTheme.blue,
      );
      const s3 = AppSettings(
        themeMode: AppThemeMode.light,
        boardTheme: BoardTheme.wood,
      );

      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
    });

    group('toJson & fromJson', () {
      test('round-trip for all theme modes and board themes', () {
        for (final mode in AppThemeMode.values) {
          for (final board in BoardTheme.values) {
            final settings = AppSettings(themeMode: mode, boardTheme: board);
            final json = settings.toJson();
            final restored = AppSettings.fromJson(json);
            expect(restored, equals(settings));
          }
        }
      });

      test('fromJson with null returns default settings', () {
        final restored = AppSettings.fromJson(null);
        expect(restored, const AppSettings());
      });

      test('fromJson with empty map returns default settings', () {
        final restored = AppSettings.fromJson({});
        expect(restored, const AppSettings());
      });

      test('fromJson with wrong type falls back to default', () {
        final restored = AppSettings.fromJson({
          'themeMode': 12345,
          'boardTheme': 67890,
        });
        expect(restored.themeMode, AppThemeMode.system);
        expect(restored.boardTheme, BoardTheme.wood);
      });

      test('fromJson with unknown enum string falls back to default', () {
        final restored = AppSettings.fromJson({
          'themeMode': 'high_contrast',
          'boardTheme': 'neon_rainbow',
        });
        expect(restored.themeMode, AppThemeMode.system);
        expect(restored.boardTheme, BoardTheme.wood);
      });
    });
  });
}
