import 'dart:convert';

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:equatable/equatable.dart';

/// Dữ liệu lưu ván cờ đang chơi.
final class SavedGame extends Equatable {
  const SavedGame({
    required this.startFen,
    required this.moves,
    required this.config,
  });

  /// Thế cờ bắt đầu ván (FEN).
  final String startFen;

  /// Danh sách nước đi theo định dạng UCI (vd. ['e2e4', 'e7e5']).
  final List<String> moves;

  /// Cấu hình ván chơi (chế độ, màu quân, mức độ khó).
  final GameConfig config;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'startFen': startFen,
    'moves': moves,
    'mode': config.mode.name,
    'humanColor': config.humanColor.name,
    'level': config.level.name,
  };

  String encode() => jsonEncode(toJson());

  static SavedGame decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return SavedGame.fromJson(decoded);
  }

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported version');
    }
    final startFen = json['startFen'];
    if (startFen is! String) {
      throw const FormatException('Invalid startFen');
    }
    final rawMoves = json['moves'];
    if (rawMoves is! List) {
      throw const FormatException('Invalid moves');
    }
    final moves = <String>[];
    for (final m in rawMoves) {
      if (m is! String) {
        throw const FormatException('Move is not a string');
      }
      moves.add(m);
    }
    final rawMode = json['mode'];
    final mode = GameMode.values.where((m) => m.name == rawMode).firstOrNull;
    if (mode == null) {
      throw const FormatException('Invalid mode');
    }
    final rawColor = json['humanColor'];
    final humanColor = PieceColor.values
        .where((c) => c.name == rawColor)
        .firstOrNull;
    if (humanColor == null) {
      throw const FormatException('Invalid humanColor');
    }
    final rawLevel = json['level'];
    final level = AiLevel.values.where((l) => l.name == rawLevel).firstOrNull;
    if (level == null) {
      throw const FormatException('Invalid level');
    }

    final config = mode == GameMode.pvp
        ? const GameConfig.pvp()
        : GameConfig(mode: mode, humanColor: humanColor, level: level);

    return SavedGame(
      startFen: startFen,
      moves: List.unmodifiable(moves),
      config: config,
    );
  }

  @override
  List<Object?> get props => [startFen, moves, config];
}
