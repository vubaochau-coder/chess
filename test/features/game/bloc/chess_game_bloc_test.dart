import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/audio/sound_effect.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

// Ô theo quy ước index = hàng * 8 + cột, hàng 0 là hàng 8.
const e2 = 52, e4 = 36, e7 = 12, e5 = 28, f2 = 53, f3 = 45, g2 = 54, g4 = 38;
const d8 = 3, h4 = 39, d2 = 51, d4 = 35, g1 = 62, g8 = 6, f6 = 21;

void main() {
  late MockSoundPlayer sound;
  late MockChessAi ai;

  setUpAll(registerFallbacks);

  setUp(() {
    sound = MockSoundPlayer();
    ai = MockChessAi();
  });

  ChessGameBloc buildBloc({
    GameConfig config = const GameConfig.pvp(),
    GamePosition? startPosition,
  }) => ChessGameBloc(
    soundPlayer: sound,
    ai: ai,
    config: config,
    startPosition: startPosition,
  );

  test('starts at the initial position with white to move', () {
    final bloc = buildBloc();
    expect(bloc.state.history, hasLength(1));
    expect(bloc.state.position.whiteToMove, isTrue);
    expect(bloc.state.status, GameStatus.playing);
    expect(bloc.state.selected, isNull);
  });

  blocTest<ChessGameBloc, ChessGameState>(
    'BoardFlipToggled flips the board and back',
    build: buildBloc,
    act: (bloc) => bloc
      ..add(const BoardFlipToggled())
      ..add(const BoardFlipToggled()),
    expect: () => [
      isA<ChessGameState>().having((s) => s.flipped, 'flipped', true),
      isA<ChessGameState>().having((s) => s.flipped, 'flipped', false),
    ],
  );

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
      build: () =>
          buildBloc(startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1')),
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
      build: () =>
          buildBloc(startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1')),
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
      build: () =>
          buildBloc(startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1')),
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
        build: () => buildBloc(
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
        build: () => buildBloc(
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
      build: () => buildBloc(
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
    const e1 = 60, a7 = 8, a8 = 0, h7 = 15, h6 = 23, g6 = 22;
    const pve = GameConfig(mode: GameMode.pve);

    /// Máy trả lời lần lượt các nước [moves].
    void aiAnswers(List<Move> moves) {
      final queue = [...moves];
      when(() => ai.chooseMove(any(), any()))
          .thenAnswer((_) async => queue.removeAt(0));
    }

    Future<void> tap(ChessGameBloc bloc, List<int> squares) async {
      for (final square in squares) {
        bloc.add(SquareTapped(square));
        await pumpEventQueue();
      }
    }

    test('PvP never allows undo', () async {
      final bloc = buildBloc();
      await tap(bloc, [e2, e4]);
      expect(bloc.state.canUndo, isFalse);

      bloc.add(const UndoRequested());
      await pumpEventQueue();
      expect(bloc.state.moves, hasLength(1));
      await bloc.close();
    });

    blocTest<ChessGameBloc, ChessGameState>(
      'undo at initial position does not emit any state and does not play sound',
      build: () => buildBloc(config: pve),
      act: (bloc) => bloc.add(const UndoRequested()),
      expect: () => <ChessGameState>[],
      verify: (bloc) {
        expect(bloc.state.history, hasLength(1));
        expect(bloc.state.moves, isEmpty);
        verifyZeroInteractions(sound);
      },
    );

    test('undo reverts the human move and the machine reply', () async {
      aiAnswers([const Move(e7, e5)]);
      final bloc = buildBloc(config: pve);
      await tap(bloc, [e2, e4]);
      expect(bloc.state.moves, hasLength(2));

      bloc.add(const UndoRequested());
      await pumpEventQueue();

      expect(bloc.state.history, hasLength(1));
      expect(bloc.state.moves, isEmpty);
      expect(bloc.state.position.whiteToMove, isTrue);
      expect(bloc.state.position.board[e2], 'P');
      expect(bloc.state.position.board[e4], '');
      expect(bloc.state.position.board[e7], 'p');
      expect(bloc.state.lastMove, isNull);
      expect(bloc.state.undosUsed, 1);
      await bloc.close();
    });

    test(
      'undo after castling restores king, rook and castling rights',
      () async {
        aiAnswers([const Move(h7, h6)]);
        final bloc = buildBloc(
          config: pve,
          startPosition: Fen.parse(
            'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQK2R w KQkq - 1 6',
          ),
        );
        await tap(bloc, [e1, g1]);
        bloc.add(const UndoRequested());
        await pumpEventQueue();

        final board = bloc.state.position.board;
        expect(board[e1], 'K');
        expect(board[g1], '');
        expect(board[63], 'R');
        expect(board[61], '');
        expect(bloc.state.position.castling, 'KQkq');
        expect(bloc.state.position.whiteToMove, isTrue);
        await bloc.close();
      },
    );

    test('undo after promotion restores the pawn on the 7th rank', () async {
      aiAnswers([const Move(h7, g6)]);
      final bloc = buildBloc(
        config: pve,
        startPosition: Fen.parse('8/P6k/8/7p/8/8/8/K7 w - - 0 1'),
      );
      await tap(bloc, [a7, a8]);
      bloc.add(PromotionPieceSelected('q'));
      await pumpEventQueue();
      expect(bloc.state.moves, hasLength(2));

      bloc.add(const UndoRequested());
      await pumpEventQueue();

      expect(bloc.state.position.board[a7], 'P');
      expect(bloc.state.position.board[a8], '');
      expect(bloc.state.pendingPromotion, isNull);
      expect(bloc.state.position.whiteToMove, isTrue);
      await bloc.close();
    });

    test('undo after the human checkmates lets the game continue', () async {
      aiAnswers([const Move(f2, f3), const Move(g2, g4)]);
      final bloc = buildBloc(
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.black,
        ),
      );
      await pumpEventQueue();
      await tap(bloc, [e7, e5, d8, h4]);
      expect(bloc.state.status, GameStatus.checkmate);

      bloc.add(const UndoRequested());
      await pumpEventQueue();

      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.isGameOver, isFalse);
      expect(bloc.state.position.whiteToMove, isFalse);
      expect(bloc.state.moves.map((m) => m.san), ['f3', 'e5', 'g4']);
      expect(ChessRules.legalMoves(bloc.state.position, d8), isNotEmpty);
      await bloc.close();
    });

    test('undo while a piece is selected clears the selection', () async {
      aiAnswers([const Move(e7, e5)]);
      final bloc = buildBloc(config: pve);
      await tap(bloc, [e2, e4, d2]);
      expect(bloc.state.selected, d2);

      bloc.add(const UndoRequested());
      await pumpEventQueue();

      expect(bloc.state.selected, isNull);
      expect(bloc.state.legalTargets, isEmpty);
      expect(bloc.state.history, hasLength(1));
      await bloc.close();
    });

    test('undo while promotion is pending clears it', () async {
      const a1 = 56, a2 = 48, h5 = 31;
      aiAnswers([const Move(h5, h4)]);
      final bloc = buildBloc(
        config: pve,
        startPosition: Fen.parse('8/P6k/8/7p/8/8/8/K7 w - - 0 1'),
      );
      await tap(bloc, [a1, a2, a7, a8]);
      expect(bloc.state.pendingPromotion, isNotNull);

      bloc.add(const UndoRequested());
      await pumpEventQueue();

      expect(bloc.state.pendingPromotion, isNull);
      expect(bloc.state.selected, isNull);
      expect(bloc.state.legalTargets, isEmpty);
      await bloc.close();
    });

    test('undo is locked until the human plays again', () async {
      aiAnswers([const Move(e7, e5), const Move(e7, e5)]);
      final bloc = buildBloc(config: pve);
      await tap(bloc, [e2, e4]);
      bloc.add(const UndoRequested());
      await pumpEventQueue();
      expect(bloc.state.moves, isEmpty);

      // Ván không còn nước của người: không đi lại được dù còn lượt.
      expect(bloc.state.canUndo, isFalse);

      await tap(bloc, [e2, e4]);
      expect(bloc.state.canUndo, isTrue);
      expect(bloc.state.undosLeft, 2);
      await bloc.close();
    });

    test('undo cannot be used twice in a row', () async {
      aiAnswers([const Move(e7, e5), const Move(g8, f6)]);
      final bloc = buildBloc(config: pve);
      await tap(bloc, [e2, e4, g1, f3]);
      expect(bloc.state.moves, hasLength(4));

      bloc.add(const UndoRequested());
      await pumpEventQueue();
      expect(bloc.state.moves, hasLength(2));
      expect(bloc.state.canUndo, isFalse);

      bloc.add(const UndoRequested());
      await pumpEventQueue();
      expect(bloc.state.moves, hasLength(2));
      expect(bloc.state.undosUsed, 1);
      await bloc.close();
    });

    test('undo is limited to three times per game', () async {
      when(() => ai.chooseMove(any(), any()))
          .thenAnswer((_) async => const Move(e7, e5));
      final bloc = buildBloc(config: pve);
      for (var i = 0; i < ChessGameState.maxUndos; i++) {
        await tap(bloc, [e2, e4]);
        bloc.add(const UndoRequested());
        await pumpEventQueue();
      }
      expect(bloc.state.undosLeft, 0);

      await tap(bloc, [e2, e4]);
      expect(bloc.state.canUndo, isFalse);
      bloc.add(const UndoRequested());
      await pumpEventQueue();
      expect(bloc.state.moves, hasLength(2));

      bloc.add(const NewGameRequested());
      await pumpEventQueue();
      expect(bloc.state.undosLeft, ChessGameState.maxUndos);
      await bloc.close();
    });
  });

  group('hint', () {
    const pve = GameConfig(mode: GameMode.pve);

    test('PvP never offers hints', () async {
      final bloc = buildBloc();
      expect(bloc.state.canHint, isFalse);
      bloc.add(const HintRequested());
      await pumpEventQueue();
      expect(bloc.state.hint, isNull);
      verifyNever(() => ai.chooseMove(any(), any()));
      await bloc.close();
    });

    test(
      'hint uses the hard level and is shown until the human moves',
      () async {
        when(() => ai.chooseMove(any(), AiLevel.hard))
            .thenAnswer((_) async => const Move(e2, e4));
        when(() => ai.chooseMove(any(), AiLevel.medium))
            .thenAnswer((_) async => const Move(e7, e5));
        final bloc = buildBloc(config: pve);

        bloc.add(const HintRequested());
        expect(bloc.state.canHint, isTrue);
        await pumpEventQueue();

        expect(bloc.state.hint, const Move(e2, e4));
        expect(bloc.state.hintsLeft, ChessGameState.maxHints - 1);
        expect(bloc.state.canHint, isFalse, reason: 'hint already shown');
        verify(() => ai.chooseMove(any(), AiLevel.hard)).called(1);

        bloc
          ..add(const SquareTapped(e2))
          ..add(const SquareTapped(e4));
        await pumpEventQueue();
        expect(bloc.state.hint, isNull);
        expect(bloc.state.canHint, isTrue);
        await bloc.close();
      },
    );

    test('a stale hint is dropped and not counted', () async {
      final pending = Completer<Move>();
      when(() => ai.chooseMove(any(), AiLevel.hard))
          .thenAnswer((_) => pending.future);
      when(() => ai.chooseMove(any(), AiLevel.medium))
          .thenAnswer((_) async => const Move(e7, e5));
      final bloc = buildBloc(config: pve);

      bloc.add(const HintRequested());
      await pumpEventQueue();
      expect(bloc.state.isHintLoading, isTrue);

      bloc
        ..add(const SquareTapped(e2))
        ..add(const SquareTapped(e4));
      await pumpEventQueue();
      expect(bloc.state.isHintLoading, isFalse);

      pending.complete(const Move(d2, d4));
      await pumpEventQueue();
      expect(bloc.state.hint, isNull);
      expect(bloc.state.hintsUsed, 0);
      await bloc.close();
    });

    test('hints are limited to three per game', () async {
      const b8 = 1, c6 = 18;
      final hints = [
        const Move(e2, e4),
        const Move(g1, f3),
        const Move(d2, d4),
      ];
      final replies = [
        const Move(e7, e5),
        const Move(b8, c6),
        const Move(g8, f6),
      ];
      when(() => ai.chooseMove(any(), AiLevel.hard))
          .thenAnswer((_) async => hints.removeAt(0));
      when(() => ai.chooseMove(any(), AiLevel.medium))
          .thenAnswer((_) async => replies.removeAt(0));
      final bloc = buildBloc(config: pve);

      for (var i = 0; i < ChessGameState.maxHints; i++) {
        bloc.add(const HintRequested());
        await pumpEventQueue();
        final hint = bloc.state.hint!;
        if (i == ChessGameState.maxHints - 1) break;
        bloc
          ..add(SquareTapped(hint.from))
          ..add(SquareTapped(hint.to));
        await pumpEventQueue();
      }
      expect(bloc.state.hintsLeft, 0);

      bloc
        ..add(const SquareTapped(d2))
        ..add(const SquareTapped(d4));
      await pumpEventQueue();
      expect(bloc.state.canHint, isFalse);

      bloc.add(const NewGameRequested());
      await pumpEventQueue();
      expect(bloc.state.hintsLeft, ChessGameState.maxHints);
      await bloc.close();
    });
  });

  group('ResignRequested in PvP', () {
    blocTest<ChessGameBloc, ChessGameState>(
      'White resigns on White turn sets whiteResigned, plays gameEnd sound, disables undo',
      build: buildBloc,
      act: (bloc) => bloc.add(const ResignRequested()),
      expect: () => [
        isA<ChessGameState>()
            .having((s) => s.status, 'status', GameStatus.whiteResigned)
            .having((s) => s.isGameOver, 'isGameOver', isTrue)
            .having((s) => s.canUndo, 'canUndo', isFalse),
      ],
      verify: (_) {
        verify(() => sound.play(SoundEffect.gameEnd)).called(1);
      },
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'Black resigns on Black turn sets blackResigned, plays gameEnd sound, disables undo',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const SquareTapped(e2))
        ..add(const SquareTapped(e4))
        ..add(const ResignRequested()),
      skip: 2, // Skip SquareTapped events
      expect: () => [
        isA<ChessGameState>()
            .having((s) => s.status, 'status', GameStatus.blackResigned)
            .having((s) => s.isGameOver, 'isGameOver', isTrue)
            .having((s) => s.canUndo, 'canUndo', isFalse),
      ],
      verify: (_) {
        verify(() => sound.play(SoundEffect.gameEnd)).called(1);
      },
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'ResignRequested when game is already over does nothing',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const ResignRequested())
        ..add(const ResignRequested()),
      expect: () => [
        isA<ChessGameState>().having(
          (s) => s.status,
          'status',
          GameStatus.whiteResigned,
        ),
      ],
      verify: (_) {
        verify(() => sound.play(SoundEffect.gameEnd)).called(1);
      },
    );

    blocTest<ChessGameBloc, ChessGameState>(
      'ResignRequested while piece is selected clears selection and targets',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const SquareTapped(e2))
        ..add(const ResignRequested()),
      skip: 1,
      expect: () => [
        isA<ChessGameState>()
            .having((s) => s.status, 'status', GameStatus.whiteResigned)
            .having((s) => s.selected, 'selected', isNull)
            .having((s) => s.legalTargets, 'legalTargets', isEmpty),
      ],
    );
  });
}
