import 'dart:async';

import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class GameRepository {
  SavedGame? load(); // dữ liệu hỏng/không hợp lệ -> trả null và xóa dữ liệu
  Future<void> save(SavedGame game);
  Future<void> clear();
}

final class SharedPrefsGameRepository implements GameRepository {
  static const _key = 'saved_game_v1';

  final SharedPreferencesWithCache _prefs;

  SharedPrefsGameRepository(this._prefs);

  @override
  SavedGame? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;

    final SavedGame savedGame;
    try {
      savedGame = SavedGame.decode(raw);
    } catch (_) {
      unawaited(clear());
      return null;
    }

    try {
      var position = Fen.parse(savedGame.startFen);
      for (final uci in savedGame.moves) {
        final move = Move.fromUci(uci);
        if (!ChessRules.isLegalMove(position, move)) {
          unawaited(clear());
          return null;
        }
        position = ChessRules.applyMove(
          position,
          move.from,
          move.to,
          promotion: move.promotion ?? 'q',
        ).position;
      }
    } catch (_) {
      unawaited(clear());
      return null;
    }

    return savedGame;
  }

  @override
  Future<void> save(SavedGame game) async {
    await _prefs.setString(_key, game.encode());
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}

final class NoopGameRepository implements GameRepository {
  const NoopGameRepository();

  @override
  SavedGame? load() => null;

  @override
  Future<void> save(SavedGame game) async {}

  @override
  Future<void> clear() async {}
}
