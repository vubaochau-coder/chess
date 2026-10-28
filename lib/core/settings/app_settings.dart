import 'package:chess/theme/board_theme.dart';
import 'package:equatable/equatable.dart';

enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromName(String? name) {
    return switch (name) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }
}

final class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.boardTheme = BoardTheme.wood,
  });

  final AppThemeMode themeMode;
  final BoardTheme boardTheme;

  AppSettings copyWith({AppThemeMode? themeMode, BoardTheme? boardTheme}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      boardTheme: boardTheme ?? this.boardTheme,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themeMode': themeMode.name,
      'boardTheme': boardTheme.name,
    };
  }

  factory AppSettings.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return const AppSettings();
    }

    final rawThemeMode = json['themeMode'];
    final themeMode = rawThemeMode is String
        ? AppThemeMode.fromName(rawThemeMode)
        : AppThemeMode.system;

    final rawBoardTheme = json['boardTheme'];
    final boardTheme = rawBoardTheme is String
        ? BoardTheme.fromName(rawBoardTheme)
        : BoardTheme.wood;

    return AppSettings(themeMode: themeMode, boardTheme: boardTheme);
  }

  @override
  List<Object?> get props => [themeMode, boardTheme];
}
