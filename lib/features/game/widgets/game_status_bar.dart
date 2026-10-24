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
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Máy đang nghĩ…',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          );
        }

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
        };
        return Text(text, style: Theme.of(context).textTheme.titleLarge);
      },
    );
  }
}
