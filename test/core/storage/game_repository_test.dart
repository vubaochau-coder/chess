import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPrefsGameRepository repository;
  late SharedPreferencesWithCache prefs;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {'saved_game_v1'},
      ),
    );
    repository = SharedPrefsGameRepository(prefs);
  });

  group('SharedPrefsGameRepository', () {
    test('load returns null when no game is saved', () {
      expect(repository.load(), isNull);
    });

    test('save then load returns identical SavedGame', () async {
      const saved = SavedGame(
        startFen: Fen.initial,
        moves: ['e2e4', 'e7e5', 'g1f3'],
        config: GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.white,
          level: AiLevel.hard,
        ),
      );

      await repository.save(saved);
      final loaded = repository.load();
      expect(loaded, saved);
    });

    test('clear removes saved game and load returns null', () async {
      const saved = SavedGame(
        startFen: Fen.initial,
        moves: ['e2e4'],
        config: GameConfig.pvp(),
      );

      await repository.save(saved);
      expect(repository.load(), isNotNull);

      await repository.clear();
      expect(repository.load(), isNull);
    });

    test('load on corrupted JSON returns null and clears data', () async {
      await prefs.setString('saved_game_v1', '{invalid json');
      expect(prefs.getString('saved_game_v1'), isNotNull);

      final loaded = repository.load();
      expect(loaded, isNull);

      await pumpEventQueue();
      expect(prefs.getString('saved_game_v1'), isNull);
    });

    test('load on unknown version returns null and clears data', () async {
      await prefs.setString(
        'saved_game_v1',
        '{"version": 99, "startFen": "${Fen.initial}", "moves": [], "mode": "pvp", "humanColor": "white", "level": "medium"}',
      );

      final loaded = repository.load();
      expect(loaded, isNull);

      await pumpEventQueue();
      expect(prefs.getString('saved_game_v1'), isNull);
    });

    test('load on invalid startFen returns null and clears data', () async {
      await prefs.setString(
        'saved_game_v1',
        '{"version": 1, "startFen": "not a fen string", "moves": [], "mode": "pvp", "humanColor": "white", "level": "medium"}',
      );

      final loaded = repository.load();
      expect(loaded, isNull);

      await pumpEventQueue();
      expect(prefs.getString('saved_game_v1'), isNull);
    });

    test('load on illegal move returns null and clears data', () async {
      // e2e5 is an illegal move from initial position
      await prefs.setString(
        'saved_game_v1',
        '{"version": 1, "startFen": "${Fen.initial}", "moves": ["e2e5"], "mode": "pvp", "humanColor": "white", "level": "medium"}',
      );

      final loaded = repository.load();
      expect(loaded, isNull);

      await pumpEventQueue();
      expect(prefs.getString('saved_game_v1'), isNull);
    });

    test('load on move with invalid turn returns null and clears data', () async {
      // e7e5 is black's move, but white to move first
      await prefs.setString(
        'saved_game_v1',
        '{"version": 1, "startFen": "${Fen.initial}", "moves": ["e7e5"], "mode": "pvp", "humanColor": "white", "level": "medium"}',
      );

      final loaded = repository.load();
      expect(loaded, isNull);

      await pumpEventQueue();
      expect(prefs.getString('saved_game_v1'), isNull);
    });

    test('load replaying legal promotion move works correctly', () async {
      // a7a8q promotion from promo position
      const promoFen = '8/P6k/8/8/8/8/8/K7 w - - 0 1';
      const saved = SavedGame(
        startFen: promoFen,
        moves: ['a7a8q'],
        config: GameConfig.pvp(),
      );

      await repository.save(saved);
      final loaded = repository.load();
      expect(loaded, saved);
    });
  });
}
