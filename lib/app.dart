import 'dart:async';

import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/features/home/view/home_page.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChessApp extends StatelessWidget {
  const ChessApp({
    super.key,
    required this.gameRepository,
    required this.settingsRepository,
  });

  final GameRepository gameRepository;
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    // Service dùng chung cả app được tạo và dispose ở đây, rồi truyền vào bloc.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SoundPlayer>(
          create: (_) => AudioPoolSoundPlayer(),
          dispose: (player) => unawaited(player.dispose()),
        ),
        RepositoryProvider<ChessAi>(create: (_) => const IsolateChessAi()),
        RepositoryProvider<GameRepository>.value(value: gameRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
      ],
      child: BlocProvider<SettingsCubit>(
        create: (context) =>
            SettingsCubit(repository: context.read<SettingsRepository>()),
        child: BlocSelector<SettingsCubit, AppSettings, ThemeMode>(
          selector: (settings) => switch (settings.themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
          },
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'Chess',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF3B4968),
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  centerTitle: true,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                ),
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF3B4968),
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  centerTitle: true,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                ),
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              themeMode: themeMode,
              home: const HomePage(),
            );
          },
        ),
      ),
    );
  }
}
