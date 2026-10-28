import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/captured_pieces.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/game_status_bar.dart';
import 'package:chess/features/game/widgets/move_list.dart';
import 'package:chess/features/game/widgets/promotion_dialog.dart';
import 'package:chess/features/settings/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tạo [ChessGameBloc] cho màn chơi. Phần giao diện nằm ở [GameView] để test
/// widget có thể cấp bloc giả.
class GamePage extends StatelessWidget {
  const GamePage({
    super.key,
    required this.config,
    this.startPosition,
    this.restore,
  });

  final GameConfig config;
  final GamePosition? startPosition;
  final SavedGame? restore;

  @override
  Widget build(BuildContext context) {
    GameRepository? repo;
    try {
      repo = context.read<GameRepository>();
    } catch (_) {
      repo = null;
    }

    return BlocProvider(
      create: (context) => ChessGameBloc(
        soundPlayer: context.read<SoundPlayer>(),
        ai: context.read<ChessAi>(),
        gameRepository: repo,
        config: config,
        startPosition: startPosition,
        restore: restore,
      ),
      child: const GameView(),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final config = context.select((ChessGameBloc b) => b.state.config);
    final title = switch (config.mode) {
      GameMode.pvp => '2 người',
      GameMode.pve => switch (config.level) {
        AiLevel.easy => 'Máy - Dễ',
        AiLevel.medium => 'Máy - Trung bình',
        AiLevel.hard => 'Máy - Khó',
      },
    };

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
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Cài đặt',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              const GameStatusBar(),
              const SizedBox(height: 10),
              const MoveList(),
              const SizedBox(height: 10),

              // Control buttons bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.read<ChessGameBloc>().add(
                        const NewGameRequested(),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Ván mới'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocSelector<ChessGameBloc, ChessGameState, bool>(
                      selector: (state) => state.canUndo,
                      builder: (context, canUndo) {
                        return IconButton(
                          icon: const Icon(Icons.undo),
                          tooltip: 'Đi lại',
                          onPressed: canUndo
                              ? () => context.read<ChessGameBloc>().add(
                                  const UndoRequested(),
                                )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    BlocSelector<ChessGameBloc, ChessGameState, bool>(
                      selector: (state) => !state.isGameOver,
                      builder: (context, canResign) {
                        return IconButton(
                          icon: const Icon(Icons.flag),
                          tooltip: 'Đầu hàng',
                          onPressed: canResign
                              ? () => _showResignDialog(context)
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Top captured pieces
              const CapturedPieces(color: PieceColor.white),
              const SizedBox(height: 4),

              // Chess board
              Flexible(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: BlocSelector<ChessGameBloc, ChessGameState, bool>(
                      selector: (state) =>
                          state.config.mode == GameMode.pve &&
                          state.config.humanColor == PieceColor.black,
                      builder: (context, flipped) =>
                          ChessBoard(flipped: flipped),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Bottom captured pieces
              const CapturedPieces(color: PieceColor.black),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResignDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đầu hàng?'),
        content: const Text('Bạn có chắc chắn muốn đầu hàng ván cờ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đầu hàng'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ChessGameBloc>().add(const ResignRequested());
    }
  }
}
