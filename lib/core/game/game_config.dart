import 'package:chess/core/ai/ai_level.dart';
import 'package:equatable/equatable.dart';

enum GameMode { pvp, pve }

enum PieceColor { white, black }

final class GameConfig extends Equatable {
  const GameConfig({
    required this.mode,
    this.humanColor = PieceColor.white,
    this.level = AiLevel.medium,
  });

  const GameConfig.pvp()
    : mode = GameMode.pvp,
      humanColor = PieceColor.white,
      level = AiLevel.medium;

  final GameMode mode;
  final PieceColor humanColor;
  final AiLevel level;

  @override
  List<Object?> get props => [mode, humanColor, level];
}
