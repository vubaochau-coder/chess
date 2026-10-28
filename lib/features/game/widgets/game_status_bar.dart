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
    final colorScheme = Theme.of(context).colorScheme;

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
          return _Pill(
            background: colorScheme.surfaceContainerLow,
            border: colorScheme.outlineVariant,
            leading: SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.tertiary,
              ),
            ),
            text: 'Máy đang nghĩ…',
            textColor: colorScheme.onSurface,
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

        if (isCheck) {
          return _Pill(
            background: colorScheme.errorContainer,
            border: colorScheme.error,
            leading: Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: colorScheme.onErrorContainer,
            ),
            text: text,
            textColor: colorScheme.onErrorContainer,
          );
        }

        if (isGameOver) {
          return _Pill(
            background: colorScheme.primaryContainer,
            border: colorScheme.tertiary,
            leading: Icon(
              Icons.emoji_events_outlined,
              size: 18,
              color: colorScheme.tertiary,
            ),
            text: text,
            textColor: colorScheme.onPrimaryContainer,
          );
        }

        return _Pill(
          background: colorScheme.surfaceContainerLow,
          border: colorScheme.outlineVariant,
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: whiteToMove
                  ? const Color(0xFFFBF6EA)
                  : const Color(0xFF2B1D14),
              border: Border.all(color: colorScheme.outline, width: 1.5),
            ),
          ),
          text: text,
          textColor: colorScheme.onSurface,
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.background,
    required this.border,
    required this.leading,
    required this.text,
    required this.textColor,
  });

  final Color background;
  final Color border;
  final Widget leading;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
