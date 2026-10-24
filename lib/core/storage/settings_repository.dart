import 'dart:convert';

import 'package:chess/core/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}

final class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  static const String key = 'settings_v1';

  final SharedPreferencesWithCache _prefs;

  @override
  AppSettings load() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const AppSettings();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppSettings.fromJson(decoded);
      }
      return const AppSettings();
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(key, jsonEncode(settings.toJson()));
  }
}

final class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([AppSettings? initial])
    : _settings = initial ?? const AppSettings();

  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
