import 'dart:math' as math;

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:chess/features/home/cubit/home_cubit.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cờ vua',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SegmentedButton<GameMode>(
                      segments: const [
                        ButtonSegment(
                          value: GameMode.pve,
                          label: Text('Chơi với máy'),
                          icon: Icon(Icons.smart_toy_outlined),
                        ),
                        ButtonSegment(
                          value: GameMode.pvp,
                          label: Text('2 người'),
                          icon: Icon(Icons.people_outline),
                        ),
                      ],
                      selected: {state.mode},
                      onSelectionChanged: (selected) {
                        context.read<HomeCubit>().setMode(selected.first);
                      },
                    ),
                    if (state.mode == GameMode.pve) ...[
                      const SizedBox(height: 20),
                      SegmentedButton<AiLevel>(
                        segments: const [
                          ButtonSegment(value: AiLevel.easy, label: Text('Dễ')),
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
                        onSelectionChanged: (selected) {
                          context.read<HomeCubit>().setLevel(selected.first);
                        },
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<ColorChoice>(
                        segments: const [
                          ButtonSegment(
                            value: ColorChoice.white,
                            label: Text('Trắng'),
                          ),
                          ButtonSegment(
                            value: ColorChoice.black,
                            label: Text('Đen'),
                          ),
                          ButtonSegment(
                            value: ColorChoice.random,
                            label: Text('Ngẫu nhiên'),
                          ),
                        ],
                        selected: {state.colorChoice},
                        onSelectionChanged: (selected) {
                          context.read<HomeCubit>().setColorChoice(
                            selected.first,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 36),
                    if (state.hasSavedGame) ...[
                      FilledButton.tonalIcon(
                        onPressed: () => _resumeGame(context),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Tiếp tục ván đang chơi'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          textStyle: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      onPressed: () => _startGame(context, state),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bắt đầu'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
