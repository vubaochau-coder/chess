import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:chess/features/tutorial/cubit/tutorial_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TutorialCubit', () {
    test('initial state is loaded from the repository', () {
      final repository = InMemoryTutorialProgressRepository({'king'});

      expect(TutorialCubit(repository: repository).state.completed, {'king'});
    });

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
