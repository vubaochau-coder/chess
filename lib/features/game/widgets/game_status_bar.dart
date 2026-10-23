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
    return BlocSelector<ChessGameBloc, ChessGameState, (GameStatus, bool)>(
      selector: (state) => (state.status, state.position.whiteToMove),
      builder: (context, value) {
        final (status, whiteToMove) = value;
        final side = whiteToMove ? 'Trắng' : 'Đen';
        final winner = whiteToMove ? 'Đen' : 'Trắng';
        final text = switch (status) {
          GameStatus.playing => 'Lượt đi: $side',
          GameStatus.check => 'Chiếu! Lượt đi: $side',
          GameStatus.checkmate => 'Chiếu hết! $winner thắng',
          GameStatus.stalemate => 'Hết nước đi - Hòa',
        };
        return Text(text, style: Theme.of(context).textTheme.titleLarge);
      },
    );
  }
}
