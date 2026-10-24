import 'package:chess/core/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('default constructor sets themeMode to system', () {
      const settings = AppSettings();
      expect(settings.themeMode, AppThemeMode.system);
    });

    test('copyWith updates themeMode', () {
      const settings = AppSettings();
      final updated = settings.copyWith(themeMode: AppThemeMode.dark);
      expect(updated.themeMode, AppThemeMode.dark);

      final untouched = updated.copyWith();
      expect(untouched.themeMode, AppThemeMode.dark);
    });

    test('props contains themeMode', () {
      const s1 = AppSettings(themeMode: AppThemeMode.light);
      const s2 = AppSettings(themeMode: AppThemeMode.light);
      const s3 = AppSettings(themeMode: AppThemeMode.dark);

      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
    });

    group('toJson & fromJson', () {
      test('round-trip for all theme modes', () {
        for (final mode in AppThemeMode.values) {
          final settings = AppSettings(themeMode: mode);
          final json = settings.toJson();
          final restored = AppSettings.fromJson(json);
          expect(restored, equals(settings));
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
        final restored = AppSettings.fromJson({'themeMode': 12345});
        expect(restored.themeMode, AppThemeMode.system);
      });

      test('fromJson with unknown enum string falls back to default', () {
        final restored = AppSettings.fromJson({'themeMode': 'high_contrast'});
        expect(restored.themeMode, AppThemeMode.system);
      });
    });
  });
}
