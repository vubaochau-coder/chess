import 'dart:async';

import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/captured_pieces.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/game_labels.dart';
import 'package:chess/features/game/widgets/game_over_dialog.dart';
import 'package:chess/features/game/widgets/game_status_bar.dart';
import 'package:chess/features/game/widgets/move_list.dart';
import 'package:chess/features/game/widgets/promotion_dialog.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final config = context.select((ChessGameBloc b) => b.state.config);
    final (title, subtitle) = switch (config.mode) {
      GameMode.pvp => ('2 người', 'Cùng một máy'),
      GameMode.pve => ('Chơi với máy', aiLevelLabel(config.level)),
    };

    return _GameOverWatcher(
      child: BlocListener<ChessGameBloc, ChessGameState>(
        listenWhen: (previous, current) =>
            previous.pendingPromotion == null &&
            current.pendingPromotion != null,
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
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Lật bàn cờ',
                onPressed: () =>
                    context.read<ChessGameBloc>().add(const BoardFlipToggled()),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Cài đặt',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
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
                const SizedBox(height: 4),
                const _PlayerRow(bottom: false),
                Flexible(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _BoardFrame(
                        child: _FlipSelector(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ControlButton(
                          icon: Icons.refresh_rounded,
                          label: 'Ván mới',
                          onPressed: () => context.read<ChessGameBloc>().add(
                            const NewGameRequested(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: _UndoButton()),
                      const SizedBox(width: 10),
                      const Expanded(child: _ResignButton()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChessGameBloc, ChessGameState, bool>(
      selector: (state) => state.canUndo,
      builder: (context, canUndo) {
        return _ControlButton(
          icon: Icons.undo,
          label: 'Đi lại',
          onPressed: canUndo
              ? () => context.read<ChessGameBloc>().add(const UndoRequested())
              : null,
        );
      },
    );
  }
}

class _ResignButton extends StatelessWidget {
  const _ResignButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChessGameBloc, ChessGameState, bool>(
      selector: (state) => !state.isGameOver,
      builder: (context, canResign) {
        return _ControlButton(
          icon: Icons.flag,
          label: 'Đầu hàng',
          onPressed: canResign ? () => _confirmResign(context) : null,
        );
      },
    );
  }

  Future<void> _confirmResign(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.flag_outlined, color: colorScheme.tertiary),
          title: const Text('Đầu hàng?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bạn có chắc chắn muốn đầu hàng ván cờ này không?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      child: const Text('Đầu hàng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<ChessGameBloc>().add(const ResignRequested());
    }
  }
}

/// Mở [GameOverDialog] 500 ms sau khi ván kết thúc. Hẹn giờ bị hủy khi rời
/// màn chơi để không mở dialog trên màn khác.
class _GameOverWatcher extends StatefulWidget {
  const _GameOverWatcher({required this.child});

  final Widget child;

  @override
  State<_GameOverWatcher> createState() => _GameOverWatcherState();
}

class _GameOverWatcherState extends State<_GameOverWatcher> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), _show);
  }

  Future<void> _show() async {
    if (!mounted) return;
    final bloc = context.read<ChessGameBloc>();
    final state = bloc.state;
    if (!state.isGameOver) return;

    final action = await showDialog<GameOverAction>(
      context: context,
      builder: (_) => GameOverDialog(
        status: state.status,
        config: state.config,
        whiteToMove: state.position.whiteToMove,
        moveCount: state.moves.length,
      ),
    );
    if (!mounted) return;
    if (action == GameOverAction.newGame) {
      bloc.add(const NewGameRequested());
    } else if (action == GameOverAction.home) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChessGameBloc, ChessGameState>(
      listenWhen: (previous, current) =>
          !previous.isGameOver && current.isGameOver,
      listener: (context, state) => _schedule(),
      child: widget.child,
    );
  }
}

/// Chiều bàn cờ: khi chơi 2 người và bật "Tự lật bàn" thì bên tới lượt luôn ở
/// dưới; ngược lại theo state của bloc (người cầm Đen, nút Lật bàn cờ).
class _FlipSelector extends StatelessWidget {
  const _FlipSelector({required this.builder});

  final Widget Function(BuildContext context, bool flipped) builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, AppSettings, bool>(
      selector: (settings) => settings.autoFlipInPvp,
      builder: (context, autoFlip) {
        return BlocSelector<ChessGameBloc, ChessGameState, bool>(
          // Selector đổi khi đổi cài đặt: key mới để tính lại ngay.
          key: ValueKey(autoFlip),
          selector: (state) {
            final auto = autoFlip && state.config.mode == GameMode.pvp;
            return auto ? !state.position.whiteToMove : state.flipped;
          },
          builder: builder,
        );
      },
    );
  }
}

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

/// Một bên trong ván, phía trên hoặc dưới bàn cờ theo chiều bàn đang hiển thị.
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.bottom});

  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return _FlipSelector(
      builder: (context, flipped) => _PlayerInfo(isWhite: bottom != flipped),
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  const _PlayerInfo({required this.isWhite});

  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocSelector<
      ChessGameBloc,
      ChessGameState,
      (GameConfig, bool, bool)
    >(
      selector: (state) =>
          (state.config, state.position.whiteToMove, state.isGameOver),
      builder: (context, value) {
        final (config, whiteToMove, isGameOver) = value;
        final side = isWhite ? PieceColor.white : PieceColor.black;
        final opponent = isWhite ? PieceColor.black : PieceColor.white;
        final colorName = isWhite ? 'Trắng' : 'Đen';
        final isPve = config.mode == GameMode.pve;
        final isMachine = isPve && config.humanColor != side;
        final name = !isPve
            ? colorName
            : isMachine
            ? 'Máy · $colorName'
            : 'Bạn · $colorName';
        final active = !isGameOver && whiteToMove == isWhite;
        final turnLabel = !isPve
            ? 'Đang đi'
            : isMachine
            ? 'Lượt của máy'
            : 'Lượt của bạn';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _Avatar(isWhite: isWhite, isMachine: isMachine, active: active),
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
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    turnLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Máy: icon robot; người: Vua theo màu quân. Viền nhấn khi tới lượt.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.isWhite,
    required this.isMachine,
    required this.active,
  });

  final bool isWhite;
  final bool isMachine;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = active ? colorScheme.tertiary : colorScheme.onSurfaceVariant;

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainer,
        border: Border.all(
          color: active ? colorScheme.tertiary : colorScheme.outlineVariant,
        ),
      ),
      child: isMachine
          ? Icon(Icons.smart_toy_outlined, size: 20, color: accent)
          : Text(
              isWhite ? '♔︎' : '♚︎',
              style: TextStyle(fontSize: 20, height: 1, color: accent),
            ),
    );
  }
}

/// Ô điều khiển lớn: icon và nhãn nằm trong cùng một nút.
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
    final foreground = onPressed != null
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    return SizedBox(
      height: 64,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerLow,
          disabledBackgroundColor: colorScheme.surfaceContainerLow,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
