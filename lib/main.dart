import 'package:chess/app.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {'saved_game_v1'},
    ),
  );
  final gameRepository = SharedPrefsGameRepository(prefs);
  runApp(ChessApp(gameRepository: gameRepository));
}
