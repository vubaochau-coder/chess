import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/features/home/cubit/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeCubit', () {
    test('initial state has default values', () {
      final cubit = HomeCubit();
      expect(cubit.state.mode, GameMode.pve);
      expect(cubit.state.level, AiLevel.medium);
      expect(cubit.state.colorChoice, ColorChoice.white);
      expect(cubit.state.props, [
        GameMode.pve,
        AiLevel.medium,
        ColorChoice.white,
      ]);
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
