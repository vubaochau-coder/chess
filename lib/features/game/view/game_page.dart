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
          title: Text(title),
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
            children: [
              const SizedBox(height: 4),
              const GameStatusBar(),
              const SizedBox(height: 8),
              const _PlayerRow(bottom: false),
              Flexible(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _BoardFrame(
                      child: BlocSelector<ChessGameBloc, ChessGameState, bool>(
                        selector: (state) => _isFlipped(state.config),
                        builder: (context, flipped) =>
                            ChessBoard(flipped: flipped),
                      ),
                    ),
                  ),
                ),
              ),
              const _PlayerRow(bottom: true),
              const SizedBox(height: 8),
              const MoveList(),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    label: 'Ván mới',
                    onPressed: () => context.read<ChessGameBloc>().add(
                      const NewGameRequested(),
                    ),
                  ),
                  BlocSelector<ChessGameBloc, ChessGameState, bool>(
                    selector: (state) => state.canUndo,
                    builder: (context, canUndo) {
                      return _ControlButton(
                        icon: Icons.undo,
                        label: 'Đi lại',
                        onPressed: canUndo
                            ? () => context.read<ChessGameBloc>().add(
                                const UndoRequested(),
                              )
                            : null,
                      );
                    },
                  ),
                  BlocSelector<ChessGameBloc, ChessGameState, bool>(
                    selector: (state) => !state.isGameOver,
                    builder: (context, canResign) {
                      return _ControlButton(
                        icon: Icons.flag,
                        label: 'Đầu hàng',
                        onPressed: canResign
                            ? () => _showResignDialog(context)
                            : null,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResignDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.flag_outlined, color: colorScheme.tertiary),
          title: const Text('Đầu hàng?'),
          content: const Text(
            'Bạn có chắc chắn muốn đầu hàng ván cờ này không?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Đầu hàng'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<ChessGameBloc>().add(const ResignRequested());
    }
  }
}

/// Người cầm Đen khi chơi với máy thì bàn cờ lật (quân Đen ở dưới).
bool _isFlipped(GameConfig config) =>
    config.mode == GameMode.pve && config.humanColor == PieceColor.black;

/// Khung viền đồng quanh bàn cờ.
class _BoardFrame extends StatelessWidget {
  const _BoardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(2), child: child),
    );
  }
}

/// Một bên trong ván: màu quân, tên (Bạn/Máy khi chơi với máy), quân đã ăn.
/// [bottom] là bên nằm dưới bàn cờ (tính cả khi bàn cờ lật).
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.bottom});

  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocSelector<ChessGameBloc, ChessGameState, (GameConfig, bool)>(
      selector: (state) => (state.config, state.position.whiteToMove),
      builder: (context, value) {
        final (config, whiteToMove) = value;
        final flipped = _isFlipped(config);
        final isWhite = bottom != flipped;
        final side = isWhite ? PieceColor.white : PieceColor.black;
        final opponent = isWhite ? PieceColor.black : PieceColor.white;
        final colorName = isWhite ? 'Trắng' : 'Đen';
        final isPve = config.mode == GameMode.pve;
        final isHuman = config.humanColor == side;
        final name = !isPve
            ? colorName
            : isHuman
            ? 'Bạn · $colorName'
            : 'Máy · $colorName';
        final active = whiteToMove == isWhite;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWhite
                      ? const Color(0xFFFBF6EA)
                      : const Color(0xFF2B1D14),
                  border: Border.all(
                    color: active
                        ? colorScheme.tertiary
                        : colorScheme.outlineVariant,
                    width: active ? 2 : 1,
                  ),
                ),
                child: isPve
                    ? Icon(
                        isHuman
                            ? Icons.person_outline_rounded
                            : Icons.smart_toy_outlined,
                        size: 18,
                        color: isWhite
                            ? const Color(0xFF2B1D14)
                            : const Color(0xFFFBF6EA),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    CapturedPieces(color: opponent),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Nút điều khiển cỡ lớn có nhãn bên dưới; chạm vào nhãn cũng kích hoạt nút.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          tooltip: label,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            fixedSize: const Size(76, 50),
            backgroundColor: colorScheme.surfaceContainerLow,
            foregroundColor: colorScheme.onSurface,
            disabledBackgroundColor: colorScheme.surfaceContainerLow,
            disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
              alpha: 0.4,
            ),
            side: BorderSide(color: colorScheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onPressed,
          child: ExcludeSemantics(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
