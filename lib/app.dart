import 'dart:async';

import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/feedback_sound_player.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:chess/features/home/view/home_page.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChessApp extends StatelessWidget {
  const ChessApp({
    super.key,
    required this.gameRepository,
    required this.settingsRepository,
    required this.tutorialProgressRepository,
  });

  final GameRepository gameRepository;
  final SettingsRepository settingsRepository;
  final TutorialProgressRepository tutorialProgressRepository;

  @override
  Widget build(BuildContext context) {
    // Service dùng chung cả app được tạo và dispose ở đây, rồi truyền vào bloc.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChessAi>(create: (_) => const IsolateChessAi()),
        RepositoryProvider<GameRepository>.value(value: gameRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<TutorialProgressRepository>.value(
          value: tutorialProgressRepository,
        ),
      ],
      child: BlocProvider<SettingsCubit>(
        create: (context) =>
            SettingsCubit(repository: context.read<SettingsRepository>()),
        // Âm thanh đọc cài đặt mỗi lần phát nên phải nằm dưới SettingsCubit.
        child: RepositoryProvider<SoundPlayer>(
          create: (context) => FeedbackSoundPlayer(
            AudioPoolSoundPlayer(),
            () => context.read<SettingsCubit>().state,
          ),
          dispose: (player) => unawaited(player.dispose()),
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
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: themeMode,
                home: const HomePage(),
              );
            },
          ),
        ),
      ),
    );
  }
}
