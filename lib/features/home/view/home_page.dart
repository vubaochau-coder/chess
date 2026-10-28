import 'dart:math' as math;

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/home/cubit/home_cubit.dart';
import 'package:chess/features/settings/view/settings_page.dart';
import 'package:chess/theme/app_theme.dart';
import 'package:chess/theme/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                        _ResumeCard(onTap: () => _resumeGame(context)),
                      ],
                      const SizedBox(height: 24),
                      const SectionLabel('Chế độ'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.smart_toy_outlined,
                              title: 'Chơi với máy',
                              subtitle: 'Ba mức độ khó',
                              selected: state.mode == GameMode.pve,
                              onTap: () => cubit.setMode(GameMode.pve),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.people_outline,
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
                      FilledButton(
                        onPressed: () => _startGame(context, state),
                        child: const Text('Bắt đầu'),
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

/// Emblem, tên game và đường kẻ trang trí.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.tertiary),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainer,
              border: Border.all(color: colorScheme.outline),
            ),
            child: const Center(child: PieceView(piece: 'N', size: 44)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Cờ vua',
          style: theme.textTheme.displaySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Trí tuệ & Chiến thuật đỉnh cao',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.6,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 70, height: 1, color: colorScheme.outline),
            const SizedBox(width: 10),
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 7,
                height: 7,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 70, height: 1, color: colorScheme.outline),
          ],
        ),
      ],
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
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
                      'Quay lại đúng thế cờ bạn đã dừng',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
      child: Material(
        color: selected
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colorScheme.tertiary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: selected
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.serifFamily,
                    fontSize: 20,
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
    );
  }
}
