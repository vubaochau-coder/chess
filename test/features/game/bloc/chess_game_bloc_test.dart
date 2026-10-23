import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

// Ô theo quy ước index = hàng * 8 + cột, hàng 0 là hàng 8.
const e2 = 52, e4 = 36, e7 = 12, e5 = 28, f2 = 53, f3 = 45, g2 = 54, g4 = 38;
const d8 = 3, h4 = 39;

void main() {
  late MockSoundPlayer sound;

  setUpAll(registerFallbacks);

  setUp(() {
    sound = MockSoundPlayer();
  });

  ChessGameBloc buildBloc() => ChessGameBloc(soundPlayer: sound);

  test('starts at the initial position with white to move', () {
    final bloc = buildBloc();
    expect(bloc.state.history, hasLength(1));
    expect(bloc.state.position.whiteToMove, isTrue);
    expect(bloc.state.status, GameStatus.playing);
    expect(bloc.state.selected, isNull);
  });

  blocTest<ChessGameBloc, ChessGameState>(
    'selecting an own piece exposes its legal targets',
    build: buildBloc,
    act: (bloc) => bloc.add(const SquareTapped(e2)),
    expect: () => [
      isA<ChessGameState>().having((s) => s.selected, 'selected', e2).having(
        (s) => s.legalTargets,
        'legalTargets',
        [44, e4],
      ),
    ],
    verify: (_) => verify(() => sound.play(SoundEffect.select)).called(1),
  );

  blocTest<ChessGameBloc, ChessGameState>(
    'tapping the selected piece again clears the selection',
    build: buildBloc,
    act: (bloc) => bloc
      ..add(const SquareTapped(e2))
      ..add(const SquareTapped(e2)),
    skip: 1,
    expect: () => [
      isA<ChessGameState>()
          .having((s) => s.selected, 'selected', isNull)
          .having((s) => s.legalTargets, 'legalTargets', isEmpty),
    ],
  );

  blocTest<ChessGameBloc, ChessGameState>(
    'tapping an opponent piece or empty square without selection does nothing',
    build: buildBloc,
    act: (bloc) => bloc
      ..add(const SquareTapped(e7))
      ..add(const SquareTapped(e4)),
    expect: () => <ChessGameState>[],
    verify: (_) => verifyNever(() => sound.play(any())),
  );

  blocTest<ChessGameBloc, ChessGameState>(
    'moving to a legal target appends to history and passes the turn',
    build: buildBloc,
    act: (bloc) => bloc
      ..add(const SquareTapped(e2))
      ..add(const SquareTapped(e4)),
    skip: 1,
    expect: () => [
      isA<ChessGameState>()
          .having((s) => s.history, 'history', hasLength(2))
          .having((s) => s.position.board[e4], 'e4', 'P')
          .having((s) => s.position.whiteToMove, 'whiteToMove', isFalse)
          .having((s) => s.lastMove, 'lastMove', (from: e2, to: e4))
          .having((s) => s.selected, 'selected', isNull),
    ],
    verify: (_) => verify(() => sound.play(SoundEffect.move)).called(1),
  );

  blocTest<ChessGameBloc, ChessGameState>(
    'an illegal target keeps the selection and plays the illegal sound',
    build: buildBloc,
    act: (bloc) => bloc
      ..add(const SquareTapped(e2))
      ..add(const SquareTapped(e5)),
    skip: 1,
    expect: () => <ChessGameState>[],
    verify: (bloc) {
      expect(bloc.state.selected, e2);
      verify(() => sound.play(SoundEffect.illegal)).called(1);
    },
  );

  group("fool's mate", () {
    void playFoolsMate(ChessGameBloc bloc) {
      for (final square in [f2, f3, e7, e5, g2, g4, d8, h4]) {
        bloc.add(SquareTapped(square));
      }
    }

    blocTest<ChessGameBloc, ChessGameState>(
      'ends the game, marks the king in check and ignores further taps',
      build: buildBloc,
      act: (bloc) {
        playFoolsMate(bloc);
        bloc.add(const SquareTapped(e2));
      },
      verify: (bloc) {
        expect(bloc.state.status, GameStatus.checkmate);
        expect(bloc.state.isGameOver, isTrue);
        expect(bloc.state.checkSquare, 60);
        expect(bloc.state.selected, isNull);
        verify(() => sound.play(SoundEffect.gameEnd)).called(1);
      },
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'NewGameRequested resets to the initial position',
      build: buildBloc,
      act: (bloc) {
        playFoolsMate(bloc);
        bloc.add(const NewGameRequested());
      },
      verify: (bloc) {
        expect(bloc.state.history, hasLength(1));
        expect(bloc.state.status, GameStatus.playing);
        expect(bloc.state.checkSquare, isNull);
        expect(bloc.state.lastMove, isNull);
      },
    );
  });
}
