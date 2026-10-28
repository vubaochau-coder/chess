import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/features/game/widgets/game_labels.dart';
import 'package:flutter/material.dart';

/// Lựa chọn của người chơi trong [GameOverDialog].
enum GameOverAction { viewBoard, newGame, home }

/// Hộp thoại kết thúc ván: lý do, kết quả theo góc nhìn người chơi và các
/// lựa chọn tiếp theo.
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.status,
    required this.config,
    required this.whiteToMove,
    required this.moveCount,
  });

  final GameStatus status;
  final GameConfig config;

  /// Lượt đi ở thế cờ cuối (bên bị chiếu hết là bên tới lượt).
  final bool whiteToMove;

  /// Số nước đã đi (tính cả hai bên).
  final int moveCount;

  /// Bên thắng: `true` là Trắng, `false` là Đen, `null` là hòa.
  bool? get whiteWins => switch (status) {
    GameStatus.checkmate => !whiteToMove,
    GameStatus.whiteResigned => false,
    GameStatus.blackResigned => true,
    _ => null,
  };

  String get reason => switch (status) {
    GameStatus.checkmate => 'Chiếu hết',
    GameStatus.whiteResigned || GameStatus.blackResigned => 'Đầu hàng',
    GameStatus.stalemate => 'Hết nước đi',
    GameStatus.drawFiftyMove => 'Luật 50 nước',
    GameStatus.drawRepetition => 'Lặp lại 3 lần',
    GameStatus.drawInsufficientMaterial => 'Không đủ quân',
    _ => 'Kết thúc',
  };

  String get headline {
    final winner = whiteWins;
    if (winner == null) return 'Hòa';
    if (config.mode == GameMode.pve) {
      final humanIsWhite = config.humanColor == PieceColor.white;
      return winner == humanIsWhite ? 'Bạn đã thắng' : 'Bạn đã thua';
    }
    return winner ? 'Trắng thắng' : 'Đen thắng';
  }

  String get detail {
    final moves = (moveCount + 1) ~/ 2;
    return config.mode == GameMode.pve
        ? '$moves nước · Máy ${aiLevelLabel(config.level)}'
        : '$moves nước · 2 người';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final winner = whiteWins;
    final humanIsWhite = config.humanColor == PieceColor.white;
    final isPve = config.mode == GameMode.pve;
    final humanLost = winner != null && isPve && winner != humanIsWhite;
    final icon = winner == null
        ? Icons.handshake_outlined
        : humanLost
        ? Icons.flag_outlined
        : Icons.emoji_events_outlined;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: humanLost ? null : colorScheme.tertiary,
                border: Border.all(color: colorScheme.tertiary),
              ),
              child: Icon(
                icon,
                size: 34,
                color: humanLost
                    ? colorScheme.tertiary
                    : colorScheme.onTertiary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              reason.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(GameOverAction.viewBoard),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    child: const Text('Xem bàn cờ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(GameOverAction.newGame),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    child: const Text('Ván mới'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(GameOverAction.home),
              child: const Text('Về màn chính'),
            ),
          ],
        ),
      ),
    );
  }
}
