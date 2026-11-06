import 'package:chess/app.dart';
import 'package:chess/core/credits/credits.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(assetLicenses);
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {'saved_game_v1', 'settings_v1', 'tutorial_progress_v1'},
    ),
  );
  final gameRepository = SharedPrefsGameRepository(prefs);
  final settingsRepository = SharedPrefsSettingsRepository(prefs);
  final tutorialRepository = SharedPrefsTutorialProgressRepository(prefs);
  runApp(
    ChessApp(
      gameRepository: gameRepository,
      settingsRepository: settingsRepository,
      tutorialProgressRepository: tutorialRepository,
    ),
  );
}

/// Giấy phép của tài nguyên (không phải package) cần kèm theo app; hiện cùng
/// giấy phép package trong trang giấy phép của Flutter.
Stream<LicenseEntry> assetLicenses() async* {
  for (final credit in credits) {
    if (credit.licenseAsset case final asset?) {
      yield LicenseEntryWithLineBreaks([
        credit.title,
      ], await rootBundle.loadString(asset));
    }
  }
}
