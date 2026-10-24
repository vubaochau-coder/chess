import 'dart:async';

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockSoundPlayer sound;
  late MockChessAi ai;
  late MockGameRepository repo;

  setUp(() {
    sound = MockSoundPlayer();
    ai = MockChessAi();
    repo = MockGameRepository();
    when(() => repo.save(any())).thenAnswer((_) async {});
    when(repo.clear).thenAnswer((_) async {});
  });

  group('ChessGameBloc storage integration', () {
    test('initial fresh game saves initial state to repository', () {
      ChessGameBloc(
        soundPlayer: sound,
        ai: ai,
        gameRepository: repo,
        config: const GameConfig.pvp(),
      );

      final captured = verify(() => repo.save(captureAny())).captured;
      expect(captured, hasLength(1));
      final saved = captured.first as SavedGame;
      expect(saved.moves, isEmpty);
      expect(saved.startFen, Fen.initial);
      expect(saved.config.mode, GameMode.pvp);
    });

    test('saves after human move and after undo in PvP', () async {
      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: ai,
        gameRepository: repo,
        config: const GameConfig.pvp(),
      );

      // Initial save
      verify(() => repo.save(any())).called(1);

      // Human moves e2 -> e4
      bloc.add(const SquareTapped(52)); // e2
      bloc.add(const SquareTapped(36)); // e4
      await pumpEventQueue();

      final capturedMoves = verify(() => repo.save(captureAny())).captured;
      expect(capturedMoves, hasLength(1));
      final afterMove = capturedMoves.first as SavedGame;
      expect(afterMove.moves, ['e2e4']);

      // Undo
      bloc.add(const UndoRequested());
      await pumpEventQueue();

      final capturedUndo = verify(() => repo.save(captureAny())).captured;
      expect(capturedUndo, hasLength(1));
      final afterUndo = capturedUndo.first as SavedGame;
      expect(afterUndo.moves, isEmpty);

      await bloc.close();
    });

    test('saves after AI move in PvE', () async {
      final aiCompleter = Completer<Move>();
      when(() => ai.chooseMove(any(), any()))
          .thenAnswer((_) => aiCompleter.future);

      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: ai,
        gameRepository: repo,
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.white,
          level: AiLevel.easy,
        ),
      );

      // Human moves e2 -> e4
      bloc.add(const SquareTapped(52));
      bloc.add(const SquareTapped(36));
      await pumpEventQueue();

      // AI completes e7 -> e5
      aiCompleter.complete(const Move(12, 28));
      await pumpEventQueue();

      final captured = verify(() => repo.save(captureAny())).captured;
      // 1 initial + 1 human move + 1 AI move = 3 saves
      expect(captured, hasLength(3));
      final lastSaved = captured.last as SavedGame;
      expect(lastSaved.moves, ['e2e4', 'e7e5']);

      await bloc.close();
    });

    test('clears repository when game ends by checkmate or resign', () async {
      // Scholar's mate 1 move away:
      // r1bqkb1r/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4
      // White plays Qxf7# (Q at 39 to 13)
      final pos = Fen.parse(
        'r1bqkb1r/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
      );
      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: ai,
        gameRepository: repo,
        config: const GameConfig.pvp(),
        startPosition: pos,
      );

      // Initial save
      verify(() => repo.save(any())).called(1);

      // Qxf7#
      bloc.add(const SquareTapped(31)); // h5
      bloc.add(const SquareTapped(13)); // f7
      await pumpEventQueue();

      // Clear called because checkmate
      verify(repo.clear).called(1);

      await bloc.close();
    });

    test('clears repository on resign', () async {
      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: ai,
        gameRepository: repo,
        config: const GameConfig.pvp(),
      );

      bloc.add(const ResignRequested());
      await pumpEventQueue();

      verify(repo.clear).called(1);

      await bloc.close();
    });

    test(
      'restores saved game and triggers AI move when restored at AI turn',
      () async {
        final aiCompleter = Completer<Move>();
        when(() => ai.chooseMove(any(), any()))
            .thenAnswer((_) => aiCompleter.future);

        const restore = SavedGame(
          startFen: Fen.initial,
          moves: ['e2e4'], // White (human) played e2e4 -> now Black (AI)'s turn
          config: GameConfig(
            mode: GameMode.pve,
            humanColor: PieceColor.white,
            level: AiLevel.easy,
          ),
        );

        final bloc = ChessGameBloc(
          soundPlayer: sound,
          ai: ai,
          gameRepository: repo,
          config: restore.config,
          restore: restore,
        );

        // Verify restored state
        expect(bloc.state.moves.length, 1);
        expect(bloc.state.moves.first.san, 'e4');
        expect(bloc.state.position.whiteToMove, isFalse);

        // Because it's AI's turn, AI move should be requested automatically
        await pumpEventQueue();
        expect(bloc.state.isAiThinking, isTrue);

        // AI completes move e7e5
        aiCompleter.complete(const Move(12, 28));
        await pumpEventQueue();

        expect(bloc.state.moves.length, 2);
        expect(bloc.state.moves.last.san, 'e5');
        expect(bloc.state.isAiThinking, isFalse);

        await bloc.close();
      },
    );
  });
}
