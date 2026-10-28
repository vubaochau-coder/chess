import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/theme/board_theme.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit({required SettingsRepository repository})
    : _repository = repository,
      super(repository.load());

  final SettingsRepository _repository;

  void setThemeMode(AppThemeMode mode) {
    if (state.themeMode == mode) return;
    final next = state.copyWith(themeMode: mode);
    emit(next);
    unawaited(_repository.save(next));
  }

  void setBoardTheme(BoardTheme theme) {
    if (state.boardTheme == theme) return;
    final next = state.copyWith(boardTheme: theme);
    emit(next);
    unawaited(_repository.save(next));
  }
}
