import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
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
        expect(bloc.state.moves.map((m) => m.san).toList(), [
          'f3',
          'e5',
          'g4',
          'Qh4#',
        ]);
        expect(bloc.state.moves.length, bloc.state.history.length - 1);
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

  group('threefold repetition', () {
    const g1 = 62, f3 = 45, g8 = 6, f6 = 21;

    void playKnightsBackAndForth(ChessGameBloc bloc) {
      // 1. Nf3 Nf6
      bloc.add(const SquareTapped(g1));
      bloc.add(const SquareTapped(f3));
      bloc.add(const SquareTapped(g8));
      bloc.add(const SquareTapped(f6));
      // 2. Ng1 Ng8 (occurrence 2)
      bloc.add(const SquareTapped(f3));
      bloc.add(const SquareTapped(g1));
      bloc.add(const SquareTapped(f6));
      bloc.add(const SquareTapped(g8));
      // 3. Nf3 Nf6
      bloc.add(const SquareTapped(g1));
      bloc.add(const SquareTapped(f3));
      bloc.add(const SquareTapped(g8));
      bloc.add(const SquareTapped(f6));
      // 4. Ng1 Ng8 (occurrence 3 -> drawRepetition)
      bloc.add(const SquareTapped(f3));
      bloc.add(const SquareTapped(g1));
      bloc.add(const SquareTapped(f6));
      bloc.add(const SquareTapped(g8));
    }

    blocTest<ChessGameBloc, ChessGameState>(
      'repetition ends game with drawRepetition and ignores further taps',
      build: buildBloc,
      act: (bloc) {
        playKnightsBackAndForth(bloc);
        bloc.add(const SquareTapped(e2));
      },
      verify: (bloc) {
        expect(bloc.state.status, GameStatus.drawRepetition);
        expect(bloc.state.isGameOver, isTrue);
        expect(bloc.state.selected, isNull);
        verify(() => sound.play(SoundEffect.gameEnd)).called(1);
      },
    );
  });

  group('pawn promotion', () {
    const a7 = 8, a8 = 0, a2 = 48, a1 = 56, b8 = 1;

    test('invalid promotion piece throws ArgumentError', () {
      expect(() => PromotionPieceSelected('x'), throwsArgumentError);
      expect(() => PromotionPieceSelected('Q'), throwsArgumentError);
    });

    blocTest<ChessGameBloc, ChessGameState>(
      'stepping pawn to last rank triggers pendingPromotion and keeps board unchanged',
      build: () => ChessGameBloc(
        soundPlayer: sound,
        startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
      ),
      act: (bloc) => bloc
        ..add(const SquareTapped(a7))
        ..add(const SquareTapped(a8)),
      verify: (bloc) {
        expect(bloc.state.pendingPromotion, (from: a7, to: a8));
        expect(bloc.state.position.board[a7], 'P');
        expect(bloc.state.position.board[a8], '');
        expect(bloc.state.selected, a7);
        verifyNever(() => sound.play(SoundEffect.move));
        verifyNever(() => sound.play(SoundEffect.promote));
      },
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'tapping squares while pendingPromotion is active is ignored',
      build: () => ChessGameBloc(
        soundPlayer: sound,
        startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
      ),
      act: (bloc) => bloc
        ..add(const SquareTapped(a7))
        ..add(const SquareTapped(a8))
        ..add(const SquareTapped(56)),
      verify: (bloc) {
        expect(bloc.state.pendingPromotion, (from: a7, to: a8));
        expect(bloc.state.position.board[a7], 'P');
      },
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'PromotionCancelled clears pendingPromotion and selected without moving',
      build: () => ChessGameBloc(
        soundPlayer: sound,
        startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
      ),
      act: (bloc) => bloc
        ..add(const SquareTapped(a7))
        ..add(const SquareTapped(a8))
        ..add(const PromotionCancelled()),
      verify: (bloc) {
        expect(bloc.state.pendingPromotion, isNull);
        expect(bloc.state.selected, isNull);
        expect(bloc.state.position.board[a7], 'P');
        expect(bloc.state.position.board[a8], '');
      },
    );

    for (final (char, expected) in [
      ('q', 'Q'),
      ('r', 'R'),
      ('b', 'B'),
      ('n', 'N'),
    ]) {
      blocTest<ChessGameBloc, ChessGameState>(
        'white pawn promotes to $expected',
        build: () => ChessGameBloc(
          soundPlayer: sound,
          startPosition: Fen.parse('8/P6k/8/7p/8/8/8/K7 w - - 0 1'),
        ),
        act: (bloc) => bloc
          ..add(const SquareTapped(a7))
          ..add(const SquareTapped(a8))
          ..add(PromotionPieceSelected(char)),
        verify: (bloc) {
          expect(bloc.state.pendingPromotion, isNull);
          expect(bloc.state.position.board[a8], expected);
          expect(bloc.state.position.board[a7], '');
          expect(bloc.state.position.whiteToMove, isFalse);
          verify(() => sound.play(SoundEffect.promote)).called(1);
        },
      );
    }

    for (final (char, expected) in [
      ('q', 'q'),
      ('r', 'r'),
      ('b', 'b'),
      ('n', 'n'),
    ]) {
      blocTest<ChessGameBloc, ChessGameState>(
        'black pawn promotes to $expected',
        build: () => ChessGameBloc(
          soundPlayer: sound,
          startPosition: Fen.parse('7k/8/8/8/7P/8/p6K/8 b - - 0 1'),
        ),
        act: (bloc) => bloc
          ..add(const SquareTapped(a2))
          ..add(const SquareTapped(a1))
          ..add(PromotionPieceSelected(char)),
        verify: (bloc) {
          expect(bloc.state.pendingPromotion, isNull);
          expect(bloc.state.position.board[a1], expected);
          expect(bloc.state.position.board[a2], '');
          expect(bloc.state.position.whiteToMove, isTrue);
          verify(() => sound.play(SoundEffect.promote)).called(1);
        },
      );
    }

    blocTest<ChessGameBloc, ChessGameState>(
      'promotion with capture and check',
      build: () => ChessGameBloc(
        soundPlayer: sound,
        startPosition: Fen.parse('1r1k4/P7/8/8/8/8/8/K7 w - - 0 1'),
      ),
      act: (bloc) => bloc
        ..add(const SquareTapped(a7))
        ..add(const SquareTapped(b8))
        ..add(PromotionPieceSelected('q')),
      verify: (bloc) {
        expect(bloc.state.position.board[b8], 'Q');
        expect(bloc.state.position.board[a7], '');
        expect(bloc.state.status, GameStatus.check);
        verify(() => sound.play(SoundEffect.check)).called(1);
      },
    );
  });

  group('undo', () {
    const e1 = 60, g1 = 62, a7 = 8, a8 = 0;

    blocTest<ChessGameBloc, ChessGameState>(
      'undo at initial position does not emit any state and does not play sound',
      build: buildBloc,
      act: (bloc) => bloc.add(const UndoRequested()),
      expect: () => <ChessGameState>[],
      verify: (bloc) {
        expect(bloc.state.history, hasLength(1));
        expect(bloc.state.moves, isEmpty);
        verifyZeroInteractions(sound);
      },
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'undo after normal move restores previous position and moves',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const SquareTapped(e2))
        ..add(const SquareTapped(e4))
        ..add(const UndoRequested()),
      skip: 2,
      expect: () => [
        isA<ChessGameState>()
            .having((s) => s.history, 'history', hasLength(1))
            .having((s) => s.moves, 'moves', isEmpty)
            .having((s) => s.position.whiteToMove, 'whiteToMove', isTrue)
            .having((s) => s.position.board[e2], 'e2', 'P')
            .having((s) => s.position.board[e4], 'e4', '')
            .having((s) => s.lastMove, 'lastMove', isNull),
      ],
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'undo after castling restores king, rook and castling rights',
      build: () => ChessGameBloc(
        soundPlayer: sound,
        startPosition: Fen.parse(
          'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQK2R w KQkq - 1 6',
        ),
      ),
      act: (bloc) => bloc
        ..add(const SquareTapped(e1))
        ..add(const SquareTapped(g1))
        ..add(const UndoRequested()),
      skip: 2,
      expect: () => [
        isA<ChessGameState>()
            .having((s) => s.position.board[e1], 'e1', 'K')
            .having((s) => s.position.board[g1], 'g1', '')
            .having((s) => s.position.board[63], 'h1', 'R')
            .having((s) => s.position.board[61], 'f1', '')
            .having((s) => s.position.castling, 'castling', 'KQkq')
            .having((s) => s.position.whiteToMove, 'whiteToMove', isTrue),
      ],
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'undo after promotion restores pawn on 7th rank and clears pendingPromotion',
      build: () => ChessGameBloc(
        soundPlayer: sound,
        startPosition: Fen.parse('8/P6k/8/7p/8/8/8/K7 w - - 0 1'),
      ),
      act: (bloc) => bloc
        ..add(const SquareTapped(a7))
        ..add(const SquareTapped(a8))
        ..add(PromotionPieceSelected('q'))
        ..add(const UndoRequested()),
      skip: 3,
      expect: () => [
        isA<ChessGameState>()
            .having((s) => s.position.board[a7], 'a7', 'P')
            .having((s) => s.position.board[a8], 'a8', '')
            .having((s) => s.pendingPromotion, 'pendingPromotion', isNull)
            .having((s) => s.position.whiteToMove, 'whiteToMove', isTrue),
      ],
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'undo after checkmate allows game to continue playing',
      build: buildBloc,
      act: (bloc) {
        for (final square in [f2, f3, e7, e5, g2, g4, d8, h4]) {
          bloc.add(SquareTapped(square));
        }
        bloc.add(const UndoRequested());
      },
      skip: 8,
      expect: () => [
        isA<ChessGameState>()
            .having((s) => s.status, 'status', GameStatus.playing)
            .having((s) => s.isGameOver, 'isGameOver', isFalse)
            .having((s) => s.position.whiteToMove, 'whiteToMove', isFalse)
            .having((s) => s.moves.map((m) => m.san).toList(), 'moves', [
              'f3',
              'e5',
              'g4',
            ]),
      ],
      verify: (bloc) {
        // Can make another legal move after undoing checkmate
        final legalMoves = ChessRules.legalMoves(bloc.state.position, d8);
        expect(legalMoves, isNotEmpty);
      },
    );
  });
}
