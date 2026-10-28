import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPrefsTutorialProgressRepository repository;
  late SharedPreferencesWithCache prefs;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {SharedPrefsTutorialProgressRepository.key},
      ),
    );
    repository = SharedPrefsTutorialProgressRepository(prefs);
  });

  group('SharedPrefsTutorialProgressRepository', () {
    test('load returns an empty set when nothing is saved', () {
      expect(repository.load(), isEmpty);
    });

    test('save then load returns the saved ids', () async {
      await repository.save({'knight', 'king'});

      expect(repository.load(), {'king', 'knight'});
    });

    test('load returns an empty set for corrupted data', () async {
      await prefs.setString(SharedPrefsTutorialProgressRepository.key, '{{');

      expect(repository.load(), isEmpty);
    });

    test('load ignores non-string entries', () async {
      await prefs.setString(
        SharedPrefsTutorialProgressRepository.key,
        '["king", 3, null]',
      );

      expect(repository.load(), {'king'});
    });
  });
}
