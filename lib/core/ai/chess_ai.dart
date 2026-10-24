import 'dart:isolate';

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/search.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/move.dart';

abstract interface class ChessAi {
  Future<Move> chooseMove(List<GamePosition> history, AiLevel level);
}

final class IsolateChessAi implements ChessAi {
  const IsolateChessAi({this.minDelay = const Duration(milliseconds: 400)});

  final Duration minDelay;

  @override
  Future<Move> chooseMove(List<GamePosition> history, AiLevel level) async {
    final results = await Future.wait([
      Isolate.run(() => search(history, level.config).bestMove),
      Future<void>.delayed(minDelay),
    ]);
    return results.first as Move;
  }
}
