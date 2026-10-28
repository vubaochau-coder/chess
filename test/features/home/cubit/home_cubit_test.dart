import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:chess/features/home/cubit/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  group('HomeCubit', () {
    test('initial state has default values', () {
      final cubit = HomeCubit();
      expect(cubit.state.mode, GameMode.pve);
      expect(cubit.state.level, AiLevel.medium);
      expect(cubit.state.colorChoice, ColorChoice.white);
      expect(cubit.state.hasSavedGame, isFalse);
      expect(cubit.state.props, [
        GameMode.pve,
        AiLevel.medium,
        ColorChoice.white,
        null,
      ]);
    });

    test('initial state detects saved game when repository has one', () {
      final repo = MockGameRepository();
      when(repo.load).thenReturn(
        const SavedGame(
          startFen: Fen.initial,
          moves: ['e2e4'],
          config: GameConfig.pvp(),
        ),
      );

      final cubit = HomeCubit(repo);
      expect(cubit.state.hasSavedGame, isTrue);
    });

    test('refresh updates hasSavedGame when game is deleted or created', () {
      final repo = MockGameRepository();
      when(repo.load).thenReturn(null);

      final cubit = HomeCubit(repo);
      expect(cubit.state.hasSavedGame, isFalse);

      when(repo.load).thenReturn(
        const SavedGame(
          startFen: Fen.initial,
          moves: ['e2e4'],
          config: GameConfig.pvp(),
        ),
      );
      cubit.refresh();
      expect(cubit.state.hasSavedGame, isTrue);

      when(repo.load).thenReturn(null);
      cubit.refresh();
      expect(cubit.state.hasSavedGame, isFalse);
    });

    blocTest<HomeCubit, HomeState>(
      'setMode emits updated mode',
      build: HomeCubit.new,
      act: (cubit) => cubit.setMode(GameMode.pvp),
      expect: () => [
        const HomeState(
          mode: GameMode.pvp,
          level: AiLevel.medium,
          colorChoice: ColorChoice.white,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'setLevel emits updated level',
      build: HomeCubit.new,
      act: (cubit) => cubit.setLevel(AiLevel.hard),
      expect: () => [
        const HomeState(
          mode: GameMode.pve,
          level: AiLevel.hard,
          colorChoice: ColorChoice.white,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'setColorChoice emits updated colorChoice',
      build: HomeCubit.new,
      act: (cubit) => cubit.setColorChoice(ColorChoice.black),
      expect: () => [
        const HomeState(
          mode: GameMode.pve,
          level: AiLevel.medium,
          colorChoice: ColorChoice.black,
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'chaining multiple updates emits each state correctly',
      build: HomeCubit.new,
      act: (cubit) => cubit
        ..setMode(GameMode.pvp)
        ..setLevel(AiLevel.easy)
        ..setColorChoice(ColorChoice.random),
      expect: () => [
        const HomeState(
          mode: GameMode.pvp,
          level: AiLevel.medium,
          colorChoice: ColorChoice.white,
        ),
        const HomeState(
          mode: GameMode.pvp,
          level: AiLevel.easy,
          colorChoice: ColorChoice.white,
        ),
        const HomeState(
          mode: GameMode.pvp,
          level: AiLevel.easy,
          colorChoice: ColorChoice.random,
        ),
      ],
    );
  });
}
