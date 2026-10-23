import 'dart:io';

import 'package:chess/core/ai/search_board.dart';
import 'package:chess/core/engine/chess_rules.dart';

int perft(SearchBoard board, int depth) {
  if (depth == 0) return 1;

  final moves = <int>[];
  board.generateLegalMoves(moves);
  if (depth == 1) return moves.length;

  var nodes = 0;
  for (var i = 0; i < moves.length; i++) {
    board.makeMove(moves[i]);
    nodes += perft(board, depth - 1);
    board.unmakeMove();
  }
  return nodes;
}

void main() {
  final board = SearchBoard.fromPosition(GamePosition.initial());
  const depth = 5;

  stdout.writeln('Chạy benchmark perft độ sâu $depth từ thế ban đầu...');
  final sw = Stopwatch()..start();
  final nodes = perft(board, depth);
  sw.stop();

  final ms = sw.elapsedMilliseconds;
  final nps = ms > 0 ? (nodes * 1000 / ms).round() : 0;
  stdout.writeln('Kết quả: $nodes nodes trong ${ms}ms ($nps nodes/s)');
}
