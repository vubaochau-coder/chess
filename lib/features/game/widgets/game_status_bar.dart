import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dòng trạng thái ván cờ. Chỉ rebuild khi trạng thái hoặc lượt đi đổi,
/// không rebuild khi người chơi chọn quân.
class GameStatusBar extends StatelessWidget {
  const GameStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocSelector<
      ChessGameBloc,
      ChessGameState,
      (GameStatus, bool, bool)
    >(
      selector: (state) =>
          (state.status, state.position.whiteToMove, state.isAiThinking),
      builder: (context, value) {
        final (status, whiteToMove, isAiThinking) = value;

        if (isAiThinking) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Máy đang nghĩ…',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final isCheck = status == GameStatus.check;
        final isGameOver = status.isGameOver;
        final side = whiteToMove ? 'Trắng' : 'Đen';
        final winner = whiteToMove ? 'Đen' : 'Trắng';
        final text = switch (status) {
          GameStatus.playing => 'Lượt đi: $side',
          GameStatus.check => 'Chiếu! Lượt đi: $side',
          GameStatus.checkmate => 'Chiếu hết! $winner thắng',
          GameStatus.stalemate => 'Hết nước đi - Hòa',
          GameStatus.drawFiftyMove => 'Hòa - luật 50 nước',
          GameStatus.drawRepetition => 'Hòa - lặp lại 3 lần',
          GameStatus.drawInsufficientMaterial =>
            'Hòa - không đủ quân chiếu hết',
          GameStatus.whiteResigned => 'Trắng đầu hàng - Đen thắng',
          GameStatus.blackResigned => 'Đen đầu hàng - Trắng thắng',
        };

        final containerBg = isCheck
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : isGameOver
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

        final borderColor = isCheck
            ? colorScheme.error.withValues(alpha: 0.4)
            : colorScheme.outlineVariant.withValues(alpha: 0.5);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCheck)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                )
              else if (isGameOver)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: whiteToMove ? Colors.white : Colors.grey.shade900,
                      border: Border.all(
                        color: whiteToMove
                            ? Colors.grey.shade500
                            : Colors.grey.shade700,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCheck ? colorScheme.error : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
