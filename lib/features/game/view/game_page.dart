import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/captured_pieces.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/game_status_bar.dart';
import 'package:chess/features/game/widgets/move_list.dart';
import 'package:chess/features/game/widgets/promotion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tạo [ChessGameBloc] cho màn chơi. Phần giao diện nằm ở [GameView] để test
/// widget có thể cấp bloc giả.
class GamePage extends StatelessWidget {
  const GamePage({super.key, this.startPosition});

  final GamePosition? startPosition;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChessGameBloc(
        soundPlayer: context.read<SoundPlayer>(),
        startPosition: startPosition,
      ),
      child: const GameView(),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChessGameBloc, ChessGameState>(
      listenWhen: (previous, current) =>
          previous.pendingPromotion == null && current.pendingPromotion != null,
      listener: (context, state) async {
        final bloc = context.read<ChessGameBloc>();
        final piece = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (_) => PromotionDialog(white: state.position.whiteToMove),
        );
        if (piece == null) {
          bloc.add(const PromotionCancelled());
        } else {
          bloc.add(PromotionPieceSelected(piece));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameStatusBar(),
              const SizedBox(height: 8),
              const MoveList(),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () =>
                    context.read<ChessGameBloc>().add(const NewGameRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text('Ván mới'),
              ),
              const SizedBox(height: 8),
              const CapturedPieces(color: PieceColor.white),
              const SizedBox(height: 4),
              const Flexible(child: ChessBoard()),
              const SizedBox(height: 4),
              const CapturedPieces(color: PieceColor.black),
            ],
          ),
        ),
      ),
    );
  }
}
