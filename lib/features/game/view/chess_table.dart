import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/chess_utils.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/board_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChessTable extends StatelessWidget {
  const ChessTable({super.key});
  static const commonSize = 50.0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChessGameBloc()
            ..add(ChessGameInit(initGameState: ChessUtils.initGame)),
      child: _PageContent(),
    );
  }
}

class _PageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double cellSize = width / 8;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GameStatusBar(),
          const SizedBox(height: 16),
          BoardGame(size: cellSize),
        ],
      ),
    );
  }
}

class _GameStatusBar extends StatelessWidget {
  const _GameStatusBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessGameBloc, ChessGameState>(
      builder: (context, state) {
        if (state.isLoading) return const SizedBox();

        final side = state.position.whiteToMove ? 'Trắng' : 'Đen';
        final winner = state.position.whiteToMove ? 'Đen' : 'Trắng';
        final text = switch (state.status) {
          GameStatus.playing => 'Lượt đi: $side',
          GameStatus.check => 'Chiếu! Lượt đi: $side',
          GameStatus.checkmate => 'Chiếu hết! $winner thắng',
          GameStatus.stalemate => 'Hết nước đi - Hòa',
        };

        return Column(
          children: [
            Text(text, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                BlocProvider.of<ChessGameBloc>(context)
                    .add(ChessGameInit(initGameState: ChessUtils.initGame));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Ván mới'),
            ),
          ],
        );
      },
    );
  }
}
