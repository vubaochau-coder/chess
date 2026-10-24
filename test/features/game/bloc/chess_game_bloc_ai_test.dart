import 'dart:async';

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/ai/search.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

const e2 = 52, e4 = 36, e7 = 12, e5 = 28, g1 = 62, f3 = 45, b8 = 1, c6 = 18;

class DirectSearchChessAi implements ChessAi {
  const DirectSearchChessAi({this.seed = 20261024});

  final int seed;

  @override
  Future<Move> chooseMove(List<GamePosition> history, AiLevel level) async {
    final cfg = SearchConfig(
      maxDepth: level.config.maxDepth,
      timeLimit: level.config.timeLimit,
      useQuiescence: level.config.useQuiescence,
      useTranspositionTable: level.config.useTranspositionTable,
      randomMarginCp: level.config.randomMarginCp,
      blunderChance: level.config.blunderChance,
      seed: seed,
    );
    final result = search(history, cfg);
    return result.bestMove;
  }
}

void main() {
  late MockSoundPlayer sound;
  late MockChessAi mockAi;

  setUpAll(registerFallbacks);

  setUp(() {
    sound = MockSoundPlayer();
    mockAi = MockChessAi();
  });

  group('PvE AI integration with MockChessAi', () {
    test('human moves -> AI moves automatically; taps while AI thinking are ignored', () async {
      final aiCompleter = Completer<Move>();
      when(() => mockAi.chooseMove(any(), any()))
          .thenAnswer((_) => aiCompleter.future);

      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: mockAi,
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.white,
          level: AiLevel.medium,
        ),
      );

      // Người đi 1. e2e4
      bloc.add(const SquareTapped(e2));
      bloc.add(const SquareTapped(e4));
      await pumpEventQueue();

      expect(bloc.state.moves.length, 1);
      expect(bloc.state.moves.first.san, 'e4');
      expect(bloc.state.isAiThinking, isTrue);

      // Trong lúc máy đang nghĩ, chạm vào ô bị bỏ qua hoàn toàn
      bloc.add(const SquareTapped(e7));
      bloc.add(const SquareTapped(e5));
      await pumpEventQueue();

      expect(bloc.state.selected, isNull);
      expect(bloc.state.moves.length, 1);

      // Máy hoàn thành tính toán: đi 1... e7e5
      aiCompleter.complete(const Move(e7, e5));
      await pumpEventQueue();

      expect(bloc.state.isAiThinking, isFalse);
      expect(bloc.state.moves.length, 2);
      expect(bloc.state.moves.last.san, 'e5');
      expect(bloc.state.isHumanTurn, isTrue);
      expect(bloc.state.position.whiteToMove, isTrue);

      await bloc.close();
    });

    test(
      'NewGameRequested while AI is thinking discards old AI move',
      () async {
        final aiCompleter = Completer<Move>();
        when(() => mockAi.chooseMove(any(), any()))
            .thenAnswer((_) => aiCompleter.future);

        final bloc = ChessGameBloc(
          soundPlayer: sound,
          ai: mockAi,
          config: const GameConfig(
            mode: GameMode.pve,
            humanColor: PieceColor.white,
            level: AiLevel.medium,
          ),
        );

        // Người đi 1. e2e4 -> máy bắt đầu nghĩ
        bloc.add(const SquareTapped(e2));
        bloc.add(const SquareTapped(e4));
        await pumpEventQueue();

        expect(bloc.state.isAiThinking, isTrue);
        expect(bloc.state.gameId, 0);

        // Người bấm ván mới trong lúc máy đang nghĩ
        bloc.add(const NewGameRequested());
        await pumpEventQueue();

        expect(bloc.state.gameId, 1);
        expect(bloc.state.history.length, 1);
        expect(bloc.state.moves, isEmpty);
        expect(bloc.state.isAiThinking, isFalse);

        // Kết quả cũ của AI trả về sau khi ván mới đã bắt đầu
        aiCompleter.complete(const Move(e7, e5));
        await pumpEventQueue();

        // Kết quả cũ phải bị bỏ qua, ván mới không bị áp dụng
        expect(bloc.state.history.length, 1);
        expect(bloc.state.moves, isEmpty);
        expect(bloc.state.isAiThinking, isFalse);

        await bloc.close();
      },
    );

    test('UndoRequested while AI is thinking discards old AI move', () async {
      final aiCompleter = Completer<Move>();
      when(() => mockAi.chooseMove(any(), any()))
          .thenAnswer((_) => aiCompleter.future);

      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: mockAi,
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.white,
          level: AiLevel.medium,
        ),
      );

      // Người đi 1. e2e4 -> máy bắt đầu nghĩ
      bloc.add(const SquareTapped(e2));
      bloc.add(const SquareTapped(e4));
      await pumpEventQueue();

      expect(bloc.state.isAiThinking, isTrue);

      // Người bấm Undo trong lúc máy đang nghĩ
      bloc.add(const UndoRequested());
      await pumpEventQueue();

      // Đã quay về trước nước đi của người (0 ply)
      expect(bloc.state.history.length, 1);
      expect(bloc.state.moves, isEmpty);
      expect(bloc.state.isAiThinking, isFalse);
      expect(bloc.state.position.whiteToMove, isTrue);

      // Kết quả AI cũ trả về
      aiCompleter.complete(const Move(e7, e5));
      await pumpEventQueue();

      // Kết quả bị bỏ qua
      expect(bloc.state.history.length, 1);
      expect(bloc.state.moves, isEmpty);

      await bloc.close();
    });

    test('human plays black -> AI plays first automatically', () async {
      final aiCompleter = Completer<Move>();
      when(() => mockAi.chooseMove(any(), any()))
          .thenAnswer((_) => aiCompleter.future);

      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: mockAi,
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.black,
          level: AiLevel.medium,
        ),
      );

      // Ngay khi tạo bloc, máy cầm Trắng nên tự động tính nước đi
      await pumpEventQueue();
      expect(bloc.state.isAiThinking, isTrue);
      expect(bloc.state.isHumanTurn, isFalse);

      aiCompleter.complete(const Move(e2, e4));
      await pumpEventQueue();

      expect(bloc.state.isAiThinking, isFalse);
      expect(bloc.state.moves.length, 1);
      expect(bloc.state.moves.first.san, 'e4');
      expect(bloc.state.isHumanTurn, isTrue); // Tới lượt người cầm Đen
      expect(bloc.state.position.whiteToMove, isFalse);

      await bloc.close();
    });

    test('PvE undo reverts back to human turn (1 ply if AI thinking, 2 ply if AI already moved)', () async {
      when(() => mockAi.chooseMove(any(), any()))
          .thenAnswer((_) async => const Move(e7, e5));

      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: mockAi,
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.white,
          level: AiLevel.medium,
        ),
      );

      // Đầu ván người chưa đi nước nào -> canUndo là false
      expect(bloc.state.canUndo, isFalse);
      bloc.add(const UndoRequested());
      await pumpEventQueue();
      expect(bloc.state.history.length, 1);

      // 1. e4 -> AI trả lời e5
      bloc.add(const SquareTapped(e2));
      bloc.add(const SquareTapped(e4));
      await pumpEventQueue();

      expect(bloc.state.moves.length, 2); // e4, e5
      expect(bloc.state.canUndo, isTrue);
      expect(bloc.state.isHumanTurn, isTrue);

      // Bấm Undo: lùi cả nước e5 của AI và nước e4 của người (2 ply)
      bloc.add(const UndoRequested());
      await pumpEventQueue();

      expect(bloc.state.moves.length, 0);
      expect(bloc.state.position.whiteToMove, isTrue);
      expect(bloc.state.canUndo, isFalse);

      await bloc.close();
    });

    test(
      'PvE undo when human plays black cannot undo before human moves',
      () async {
        when(() => mockAi.chooseMove(any(), any()))
            .thenAnswer((_) async => const Move(e2, e4));

        final bloc = ChessGameBloc(
          soundPlayer: sound,
          ai: mockAi,
          config: const GameConfig(
            mode: GameMode.pve,
            humanColor: PieceColor.black,
            level: AiLevel.medium,
          ),
        );

        // Máy đi nước 1. e4
        await pumpEventQueue();
        expect(bloc.state.moves.length, 1);
        expect(bloc.state.position.whiteToMove, isFalse);

        // Người (Đen) chưa đi nước nào -> canUndo phải là false
        expect(bloc.state.canUndo, isFalse);
        bloc.add(const UndoRequested());
        await pumpEventQueue();

        // Vẫn giữ nguyên 1. e4
        expect(bloc.state.moves.length, 1);

        await bloc.close();
      },
    );
  });

  group('PvE AI integration with DirectSearchChessAi (real search)', () {
    test('Easy level makes legal moves from initial position', () async {
      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: const DirectSearchChessAi(seed: 12345),
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.black,
          level: AiLevel.easy,
        ),
      );

      await pumpEventQueue();

      expect(bloc.state.moves.length, 1);
      expect(bloc.state.isAiThinking, isFalse);
      expect(
        ChessRules.isLegalMove(
          GamePosition.initial(),
          bloc.state.moves.first.move,
        ),
        isTrue,
      );

      await bloc.close();
    });

    test('Medium level makes legal moves from initial position', () async {
      final bloc = ChessGameBloc(
        soundPlayer: sound,
        ai: const DirectSearchChessAi(seed: 54321),
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.black,
          level: AiLevel.medium,
        ),
      );

      await pumpEventQueue();

      expect(bloc.state.moves.length, 1);
      expect(bloc.state.isAiThinking, isFalse);
      expect(
        ChessRules.isLegalMove(
          GamePosition.initial(),
          bloc.state.moves.first.move,
        ),
        isTrue,
      );

      await bloc.close();
    });

    test('Medium level captures hanging queen across all 10 seeds', () async {
      // Thế cờ: rnb1kbnr/ppp1pppp/8/3q4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3
      // Trắng tốt e4 (sq 36) có thể ăn Hậu đen d5 (sq 27).
      final hangingQueenPos = Fen.parse(
        'rnb1kbnr/ppp1pppp/8/3q4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3',
      );

      for (var seed = 1; seed <= 10; seed++) {
        final bloc = ChessGameBloc(
          soundPlayer: sound,
          ai: DirectSearchChessAi(seed: seed),
          config: const GameConfig(
            mode: GameMode.pve,
            humanColor: PieceColor.black,
            level: AiLevel.medium,
          ),
          startPosition: hangingQueenPos,
        );

        await pumpEventQueue();

        expect(bloc.state.moves.length, 1, reason: 'Seed $seed made no move');
        final playedMove = bloc.state.moves.first.move;
        expect(
          playedMove.from,
          e4,
          reason: 'Seed $seed did not move pawn from e4',
        );
        expect(
          playedMove.to,
          27, // d5
          reason: 'Seed $seed did not capture queen at d5',
        );

        await bloc.close();
      }
    });
  });
}
