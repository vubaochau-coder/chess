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
    this.showCoordinates = true,
    this.showLegalMoves = true,
    this.highlightLastMove = true,
    this.autoFlipInPvp = false,
    this.soundEnabled = true,
    this.soundVolume = 0.8,
    this.hapticsEnabled = true,
  });

  final AppThemeMode themeMode;
  final BoardTheme boardTheme;
  final bool showCoordinates;
  final bool showLegalMoves;
  final bool highlightLastMove;
  final bool autoFlipInPvp;
  final bool soundEnabled;

  /// Âm lượng hiệu ứng, từ 0 đến 1.
  final double soundVolume;
  final bool hapticsEnabled;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    BoardTheme? boardTheme,
    bool? showCoordinates,
    bool? showLegalMoves,
    bool? highlightLastMove,
    bool? autoFlipInPvp,
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      boardTheme: boardTheme ?? this.boardTheme,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showLegalMoves: showLegalMoves ?? this.showLegalMoves,
      highlightLastMove: highlightLastMove ?? this.highlightLastMove,
      autoFlipInPvp: autoFlipInPvp ?? this.autoFlipInPvp,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themeMode': themeMode.name,
      'boardTheme': boardTheme.name,
      'showCoordinates': showCoordinates,
      'showLegalMoves': showLegalMoves,
      'highlightLastMove': highlightLastMove,
      'autoFlipInPvp': autoFlipInPvp,
      'soundEnabled': soundEnabled,
      'soundVolume': soundVolume,
      'hapticsEnabled': hapticsEnabled,
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

    const defaults = AppSettings();
    final rawVolume = json['soundVolume'];
    final soundVolume = rawVolume is num
        ? rawVolume.toDouble().clamp(0.0, 1.0)
        : defaults.soundVolume;

    return AppSettings(
      themeMode: themeMode,
      boardTheme: boardTheme,
      showCoordinates: _bool(json['showCoordinates'], defaults.showCoordinates),
      showLegalMoves: _bool(json['showLegalMoves'], defaults.showLegalMoves),
      highlightLastMove: _bool(
        json['highlightLastMove'],
        defaults.highlightLastMove,
      ),
      autoFlipInPvp: _bool(json['autoFlipInPvp'], defaults.autoFlipInPvp),
      soundEnabled: _bool(json['soundEnabled'], defaults.soundEnabled),
      soundVolume: soundVolume,
      hapticsEnabled: _bool(json['hapticsEnabled'], defaults.hapticsEnabled),
    );
  }

  static bool _bool(Object? raw, bool fallback) => raw is bool ? raw : fallback;

  @override
  List<Object?> get props => [
    themeMode,
    boardTheme,
    showCoordinates,
    showLegalMoves,
    highlightLastMove,
    autoFlipInPvp,
    soundEnabled,
    soundVolume,
    hapticsEnabled,
  ];
}
