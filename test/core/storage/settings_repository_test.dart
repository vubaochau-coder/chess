import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPrefsSettingsRepository repository;
  late SharedPreferencesWithCache prefs;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {'settings_v1'},
      ),
    );
    repository = SharedPrefsSettingsRepository(prefs);
  });

  group('SharedPrefsSettingsRepository', () {
    test('load returns default AppSettings when nothing saved', () {
      expect(repository.load(), const AppSettings());
    });

    test('save then load returns saved AppSettings', () async {
      const settings = AppSettings(themeMode: AppThemeMode.dark);
      await repository.save(settings);

      expect(repository.load(), equals(settings));
    });

    test(
      'load returns default AppSettings when raw is corrupted JSON',
      () async {
        await prefs.setString(
          SharedPrefsSettingsRepository.key,
          'not a json {{{',
        );
        expect(repository.load(), const AppSettings());
      },
    );

    test('load returns default AppSettings when raw is empty', () async {
      await prefs.setString(SharedPrefsSettingsRepository.key, '');
      expect(repository.load(), const AppSettings());
    });

    test(
      'load returns default AppSettings when raw is JSON array instead of map',
      () async {
        await prefs.setString(SharedPrefsSettingsRepository.key, '[1, 2, 3]');
        expect(repository.load(), const AppSettings());
      },
    );
  });

  group('InMemorySettingsRepository', () {
    test('defaults to empty AppSettings', () {
      final repo = InMemorySettingsRepository();
      expect(repo.load(), const AppSettings());
    });

    test('supports custom initial value and saving', () async {
      final repo = InMemorySettingsRepository(
        const AppSettings(themeMode: AppThemeMode.light),
      );
      expect(repo.load().themeMode, AppThemeMode.light);

      await repo.save(const AppSettings(themeMode: AppThemeMode.dark));
      expect(repo.load().themeMode, AppThemeMode.dark);
    });
  });
}
