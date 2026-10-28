import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:chess/features/tutorial/cubit/tutorial_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TutorialCubit', () {
    late InMemoryTutorialProgressRepository repository;

    blocTest<TutorialCubit, TutorialState>(
      'markCompleted emits the new set and saves it',
      setUp: () => repository = InMemoryTutorialProgressRepository(),
      build: () => TutorialCubit(repository: repository),
      act: (cubit) => cubit.markCompleted('knight'),
      expect: () => [const TutorialState(completed: {'knight'})],
      verify: (_) => expect(repository.load(), {'knight'}),
    );

    blocTest<TutorialCubit, TutorialState>(
      'markCompleted does nothing for a lesson already completed',
      build: () => TutorialCubit(
        repository: InMemoryTutorialProgressRepository({'knight'}),
      ),
      act: (cubit) => cubit.markCompleted('knight'),
      expect: () => <TutorialState>[],
    );
  });
}
