import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lưu id các bài hướng dẫn đã hoàn thành.
abstract interface class TutorialProgressRepository {
  Set<String> load();
  Future<void> save(Set<String> completed);
}

final class SharedPrefsTutorialProgressRepository
    implements TutorialProgressRepository {
  SharedPrefsTutorialProgressRepository(this._prefs);

  static const String key = 'tutorial_progress_v1';

  final SharedPreferencesWithCache _prefs;

  @override
  Set<String> load() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toSet();
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> save(Set<String> completed) async {
    final sorted = completed.toList()..sort();
    await _prefs.setString(key, jsonEncode(sorted));
  }
}

final class InMemoryTutorialProgressRepository
    implements TutorialProgressRepository {
  InMemoryTutorialProgressRepository([Set<String>? initial])
    : _completed = {...?initial};

  Set<String> _completed;

  @override
  Set<String> load() => {..._completed};

  @override
  Future<void> save(Set<String> completed) async {
    _completed = {...completed};
  }
}
