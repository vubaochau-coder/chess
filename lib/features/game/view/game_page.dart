import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/game_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tạo [ChessGameBloc] cho màn chơi. Phần giao diện nằm ở [GameView] để test
/// widget có thể cấp bloc giả.
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChessGameBloc(soundPlayer: context.read<SoundPlayer>()),
      child: const GameView(),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GameStatusBar(),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () =>
                  context.read<ChessGameBloc>().add(const NewGameRequested()),
              icon: const Icon(Icons.refresh),
              label: const Text('Ván mới'),
            ),
            const SizedBox(height: 16),
            const Flexible(child: ChessBoard()),
          ],
        ),
      ),
    );
  }
}
