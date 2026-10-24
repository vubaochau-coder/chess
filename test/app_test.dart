import 'package:chess/app.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessApp', () {
    testWidgets('themeMode updates to ThemeMode.dark when settings change', (
      tester,
    ) async {
      final settingsRepo = InMemorySettingsRepository(
        const AppSettings(themeMode: AppThemeMode.system),
      );
      const gameRepo = NoopGameRepository();

      await tester.pumpWidget(
        ChessApp(gameRepository: gameRepo, settingsRepository: settingsRepo),
      );
      await tester.pumpAndSettle();

      MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);

      // Change settings to dark
      final BuildContext context = tester.element(find.byType(MaterialApp));
      context.read<SettingsCubit>().setThemeMode(AppThemeMode.dark);
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);

      // Change settings to light
      context.read<SettingsCubit>().setThemeMode(AppThemeMode.light);
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });
  });
}
