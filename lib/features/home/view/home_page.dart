import 'dart:math' as math;

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:chess/features/game/widgets/game_labels.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/home/cubit/home_cubit.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/features/settings/view/settings_page.dart';
import 'package:chess/features/tutorial/view/tutorial_page.dart';
import 'package:chess/theme/app_theme.dart';
import 'package:chess/theme/piece_set.dart';
import 'package:chess/theme/press_scale.dart';
import 'package:chess/theme/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.random});

  final math.Random? random;

  @override
  Widget build(BuildContext context) {
    GameRepository? repo;
    try {
      repo = context.read<GameRepository>();
    } catch (_) {
      repo = null;
    }
    return BlocProvider(
      create: (_) => HomeCubit(repo),
      child: HomeView(random: random),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key, this.random});

  final math.Random? random;

  Future<void> _startGame(BuildContext context, HomeState state) async {
    final PieceColor resolvedColor;
    if (state.colorChoice == ColorChoice.random) {
      resolvedColor = (random ?? math.Random()).nextBool()
          ? PieceColor.white
          : PieceColor.black;
    } else if (state.colorChoice == ColorChoice.black) {
      resolvedColor = PieceColor.black;
    } else {
      resolvedColor = PieceColor.white;
    }

    final config = state.mode == GameMode.pvp
        ? const GameConfig.pvp()
        : GameConfig(
            mode: GameMode.pve,
            level: state.level,
            humanColor: resolvedColor,
          );

    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => GamePage(config: config)),
    );
    if (context.mounted) {
      context.read<HomeCubit>().refresh();
    }
  }

  Future<void> _resumeGame(BuildContext context) async {
    GameRepository? repo;
    try {
      repo = context.read<GameRepository>();
    } catch (_) {
      repo = null;
    }
    final saved = repo?.load();
    if (saved == null) {
      if (context.mounted) {
        context.read<HomeCubit>().refresh();
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GamePage(config: saved.config, restore: saved),
      ),
    );
    if (context.mounted) {
      context.read<HomeCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 176,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const TutorialPage()),
                );
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHigh,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              icon: Icon(
                Icons.school_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              label: const Text('Học chơi cờ', style: TextStyle(fontSize: 13)),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              );
            },
          ),

          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  final cubit = context.read<HomeCubit>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Hero(),
                      if (state.hasSavedGame) ...[
                        const SizedBox(height: 22),
                        _ResumeCard(
                          saved: state.savedGame!,
                          onTap: () => _resumeGame(context),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const SectionLabel('Chế độ'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              piece: 'N',
                              title: 'Chơi với máy',
                              subtitle: 'Ba mức độ khó',
                              selected: state.mode == GameMode.pve,
                              onTap: () => cubit.setMode(GameMode.pve),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModeCard(
                              piece: 'K',
                              title: '2 người',
                              subtitle: 'Cùng một máy',
                              selected: state.mode == GameMode.pvp,
                              onTap: () => cubit.setMode(GameMode.pvp),
                            ),
                          ),
                        ],
                      ),
                      if (state.mode == GameMode.pve) ...[
                        const SizedBox(height: 20),
                        const SectionLabel('Độ khó'),
                        const SizedBox(height: 10),
                        SegmentedButton<AiLevel>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: AiLevel.easy,
                              label: Text('Dễ'),
                            ),
                            ButtonSegment(
                              value: AiLevel.medium,
                              label: Text('Trung bình'),
                            ),
                            ButtonSegment(
                              value: AiLevel.hard,
                              label: Text('Khó'),
                            ),
                          ],
                          selected: {state.level},
                          onSelectionChanged: (selected) =>
                              cubit.setLevel(selected.first),
                        ),
                        const SizedBox(height: 18),
                        const SectionLabel('Quân của bạn'),
                        const SizedBox(height: 10),
                        SegmentedButton<ColorChoice>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: ColorChoice.white,
                              label: Text('Trắng'),
                              icon: PieceView(piece: 'K', size: 18),
                            ),
                            ButtonSegment(
                              value: ColorChoice.black,
                              label: Text('Đen'),
                              icon: PieceView(piece: 'k', size: 18),
                            ),
                            ButtonSegment(
                              value: ColorChoice.random,
                              label: Text('Ngẫu nhiên'),
                              icon: Icon(Icons.shuffle_rounded, size: 18),
                            ),
                          ],
                          selected: {state.colorChoice},
                          onSelectionChanged: (selected) =>
                              cubit.setColorChoice(selected.first),
                        ),
                      ],
                      const SizedBox(height: 28),
                      PressScale(
                        child: FilledButton(
                          onPressed: () => _startGame(context, state),
                          child: const Text('Bắt đầu'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo app và tên game.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Khung nền đặc: nửa trái logo trùng màu nền sáng, không có khung thì
        // logo bị mất một nửa.
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(30),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SvgPicture.asset(
              'assets/branding/icon.svg',
              width: 84,
              height: 84,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cờ Vua',
          style: theme.textTheme.displaySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'TRÍ TUỆ & CHIẾN THUẬT ĐỈNH CAO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2.4,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.saved, required this.onTap});

  final SavedGame saved;
  final VoidCallback onTap;

  /// Vd. `Máy · Trung bình · Nước 8 · Lượt Trắng`.
  String get _summary {
    final config = saved.config;
    final mode = config.mode == GameMode.pve
        ? 'Máy · ${aiLevelLabel(config.level)}'
        : '2 người';
    final plies = saved.moves.length;
    final whiteStarts = Fen.parse(saved.startFen).whiteToMove;
    final turn = whiteStarts == plies.isEven ? 'Trắng' : 'Đen';
    return '$mode · Nước ${plies ~/ 2 + 1} · Lượt $turn';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PressScale(
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiếp tục ván đang chơi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _summary,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ chọn chế độ; icon là quân cờ vẽ bằng bộ quân đang chọn trong cài đặt.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.piece,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  /// Ký hiệu FEN của quân làm icon.
  final String piece;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        child: Material(
          color: selected
              ? colorScheme.primaryContainer
              : AppTheme.cardColor(colorScheme),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: selected ? colorScheme.tertiary : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: BlocSelector<SettingsCubit, AppSettings, PieceSet>(
                      selector: (settings) => settings.pieceSet,
                      builder: (context, pieceSet) =>
                          PieceView(piece: piece, size: 32, pieceSet: pieceSet),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.serifFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
