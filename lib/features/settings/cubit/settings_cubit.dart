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

  void setThemeMode(AppThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  void setBoardTheme(BoardTheme theme) =>
      _update(state.copyWith(boardTheme: theme));

  void setShowCoordinates(bool value) =>
      _update(state.copyWith(showCoordinates: value));

  void setShowLegalMoves(bool value) =>
      _update(state.copyWith(showLegalMoves: value));

  void setHighlightLastMove(bool value) =>
      _update(state.copyWith(highlightLastMove: value));

  void setAutoFlipInPvp(bool value) =>
      _update(state.copyWith(autoFlipInPvp: value));

  void setSoundEnabled(bool value) =>
      _update(state.copyWith(soundEnabled: value));

  void setSoundVolume(double value) =>
      _update(state.copyWith(soundVolume: value.clamp(0.0, 1.0)));

  void setHapticsEnabled(bool value) =>
      _update(state.copyWith(hapticsEnabled: value));

  void setAnimationsEnabled(bool value) =>
      _update(state.copyWith(animationsEnabled: value));

  void _update(AppSettings next) {
    if (next == state) return;
    emit(next);
    unawaited(_repository.save(next));
  }
}
