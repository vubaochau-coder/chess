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
  const AppSettings({this.themeMode = AppThemeMode.system});

  final AppThemeMode themeMode;

  AppSettings copyWith({AppThemeMode? themeMode}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'themeMode': themeMode.name};
  }

  factory AppSettings.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return const AppSettings();
    }

    final rawThemeMode = json['themeMode'];
    final themeMode = rawThemeMode is String
        ? AppThemeMode.fromName(rawThemeMode)
        : AppThemeMode.system;

    return AppSettings(themeMode: themeMode);
  }

  @override
  List<Object?> get props => [themeMode];
}
