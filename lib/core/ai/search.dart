import 'dart:math';
import 'dart:typed_data';

import 'package:chess/core/ai/evaluation.dart';
import 'package:chess/core/ai/search_board.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/move.dart';

final class SearchConfig {
  const SearchConfig({
    required this.maxDepth,
    this.timeLimit,
    this.useQuiescence = true,
    this.useTranspositionTable = true,
    this.randomMarginCp = 0,
    this.blunderChance = 0,
    this.seed,
  });

  final int maxDepth;
  final Duration? timeLimit;
  final bool useQuiescence;
  final bool useTranspositionTable;
  final int randomMarginCp;
  final double blunderChance;
  final int? seed;
}

final class SearchResult {
  const SearchResult({
    required this.bestMove,
    required this.scoreCp,
    required this.depthReached,
    required this.nodes,
  });

  final Move bestMove;
  final int scoreCp;
  final int depthReached;
  final int nodes;
}

const int _ttExact = 0;
const int _ttLower = 1; // alpha cutoff
const int _ttUpper = 2; // failed low

final class _TranspositionTable {
  static const int size = 1 << 18; // 262,144 entries
  static const int mask = size - 1;

  final Int64List keys = Int64List(size);
  final Int32List moves = Int32List(size);
  final Int32List scores = Int32List(size);
  final Int8List depths = Int8List(size);
  final Int8List flags = Int8List(size);

  void clear() {
    keys.fillRange(0, size, 0);
    moves.fillRange(0, size, 0);
    scores.fillRange(0, size, 0);
    depths.fillRange(0, size, 0);
    flags.fillRange(0, size, 0);
  }

  void store(int key, int move, int score, int depth, int flag, int ply) {
    final idx = key & mask;
    var storedScore = score;
    if (score > 90000) {
      storedScore = score + ply;
    } else if (score < -90000) {
      storedScore = score - ply;
    }

    keys[idx] = key;
    moves[idx] = move;
    scores[idx] = storedScore;
    depths[idx] = depth;
    flags[idx] = flag;
  }
}

final class _SearchContext {
  _SearchContext({
    required this.board,
    required this.config,
    required this.historyKeys,
  }) {
    if (config.seed != null) {
      rng = Random(config.seed);
    } else {
      rng = Random();
    }
  }

  final SearchBoard board;
  final SearchConfig config;
  final List<int> historyKeys;
  late final Random rng;

  final _TranspositionTable tt = _TranspositionTable();

  final List<int> killer1 = List.filled(128, 0);
  final List<int> killer2 = List.filled(128, 0);

  final List<int> searchStackKeys = List.filled(256, 0);

  int nodes = 0;
  bool stopSearch = false;
  Stopwatch? stopwatch;

  void checkTime() {
    if (stopSearch) return;
    if (config.timeLimit != null && stopwatch != null) {
      if (stopwatch!.elapsed >= config.timeLimit!) {
        stopSearch = true;
      }
    }
  }

  bool isDraw(int ply) {
    if (board.halfmoveClock >= 100) return true;
    if (board.isInsufficientMaterial()) return true;

    // Lặp lại 3 lần: tính cả history trước đó và trong cây tìm kiếm hiện tại
    final currentKey = board.zobristKey;
    var count = 0;

    for (var i = 0; i < historyKeys.length; i++) {
      if (historyKeys[i] == currentKey) {
        count++;
        if (count >= 2) return true; // lặp lại từ history
      }
    }

    for (var i = 0; i < ply; i++) {
      if (searchStackKeys[i] == currentKey) {
        return true; // lặp lại trong cây tìm kiếm
      }
    }

    return false;
  }

  int scoreMove(int move, int ttMove, int ply) {
    if (move == ttMove) return 1000000;

    final isCap = (move & SearchBoard.flagCapture) != 0;
    final promo = SearchBoard.movePromo(move);

    if (isCap) {
      final from = SearchBoard.moveFrom(move);
      final to = SearchBoard.moveTo(move);
      final attacker = board.board[from] & 7;
      var victim = board.board[to] & 7;
      if ((move & SearchBoard.flagEnPassant) != 0) {
        victim = 1; // pawn
      }
      return 200000 + (victim * 10 - attacker);
    }

    if (promo != 0) {
      return 100000 + promo * 100;
    }

    if (killer1[ply] == move) return 90000;
    if (killer2[ply] == move) return 80000;

    return 0;
  }

  void sortMoves(List<int> moves, int ttMove, int ply) {
    if (moves.length <= 1) return;
    final scores = List<int>.filled(moves.length, 0);
    for (var i = 0; i < moves.length; i++) {
      scores[i] = scoreMove(moves[i], ttMove, ply);
    }

    // Sắp xếp đơn giản (insertion sort cho list nhỏ)
    for (var i = 1; i < moves.length; i++) {
      final m = moves[i];
      final s = scores[i];
      var j = i - 1;
      while (j >= 0 && scores[j] < s) {
        moves[j + 1] = moves[j];
        scores[j + 1] = scores[j];
        j--;
      }
      moves[j + 1] = m;
      scores[j + 1] = s;
    }
  }
}

SearchResult search(List<GamePosition> history, SearchConfig config) {
  if (history.isEmpty) {
    throw ArgumentError('history must not be empty');
  }

  final board = SearchBoard.fromPosition(history.last);
  final rootMoves = <int>[];
  board.generateLegalMoves(rootMoves);

  if (rootMoves.isEmpty) {
    throw StateError('No legal moves in position');
  }

  // Nếu chỉ có 1 nước hợp lệ -> trả ngay
  if (rootMoves.length == 1) {
    return SearchResult(
      bestMove: board.toMove(rootMoves.first),
      scoreCp: 0,
      depthReached: 1,
      nodes: 1,
    );
  }

  // Lấy các khóa zobrist của history
  final historyKeys = <int>[];
  for (final pos in history) {
    historyKeys.add(SearchBoard.fromPosition(pos).zobristKey);
  }

  final ctx = _SearchContext(
    board: board,
    config: config,
    historyKeys: historyKeys,
  );

  if (config.timeLimit != null) {
    ctx.stopwatch = Stopwatch()..start();
  }

  var bestMove = rootMoves.first;
  var bestScore = 0;
  var completedDepth = 1;
  var completedRootScores = <int, int>{};

  for (var depth = 1; depth <= config.maxDepth; depth++) {
    var alpha = -1000000;
    const beta = 1000000;
    var currentDepthBestMove = rootMoves.first;
    var currentDepthBestScore = -1000000;
    final currentDepthScores = <int, int>{};

    final ttIdx = board.zobristKey & _TranspositionTable.mask;
    final ttMove =
        (config.useTranspositionTable && ctx.tt.keys[ttIdx] == board.zobristKey)
        ? ctx.tt.moves[ttIdx]
        : 0;

    ctx.sortMoves(rootMoves, ttMove, 0);

    for (var i = 0; i < rootMoves.length; i++) {
      final m = rootMoves[i];
      ctx.searchStackKeys[0] = board.zobristKey;
      board.makeMove(m);
      ctx.nodes++;

      // Các nước bị cắt tỉa chỉ trả về cận trên (quiescence trả đúng bằng biên),
      // nên hạ cận dưới thêm randomMarginCp + 1 để mọi nước trong biên chọn
      // ngẫu nhiên của _selectFinalMove có điểm chính xác.
      final windowAlpha = alpha - config.randomMarginCp - 1;
      final score = -_negamax(ctx, depth - 1, -beta, -windowAlpha, 1);
      board.unmakeMove();

      if (ctx.stopSearch && depth > 1) {
        break;
      }

      currentDepthScores[m] = score;

      if (score > currentDepthBestScore) {
        currentDepthBestScore = score;
        currentDepthBestMove = m;
      }

      if (score > alpha) {
        alpha = score;
      }
    }

    if (ctx.stopSearch && depth > 1) {
      break;
    }

    bestMove = currentDepthBestMove;
    bestScore = currentDepthBestScore;
    completedDepth = depth;
    completedRootScores = currentDepthScores;

    // Chiếu hết tìm thấy
    if (bestScore > 90000 || bestScore < -90000) {
      break;
    }
  }

  // Xử lý ngẫu nhiên / blunder
  final chosenMove = _selectFinalMove(
    ctx,
    rootMoves,
    completedRootScores,
    bestMove,
    bestScore,
  );

  return SearchResult(
    bestMove: board.toMove(chosenMove),
    scoreCp: bestScore,
    depthReached: completedDepth,
    nodes: ctx.nodes,
  );
}

int _selectFinalMove(
  _SearchContext ctx,
  List<int> rootMoves,
  Map<int, int> rootScores,
  int bestMove,
  int bestScore,
) {
  // 1. Blunder chance
  if (ctx.config.blunderChance > 0) {
    if (ctx.rng.nextDouble() < ctx.config.blunderChance) {
      return rootMoves[ctx.rng.nextInt(rootMoves.length)];
    }
  }

  // 2. Random margin
  if (ctx.config.randomMarginCp > 0) {
    final candidateMoves = <int>[];
    final threshold = bestScore - ctx.config.randomMarginCp;
    for (final m in rootMoves) {
      final s = rootScores[m] ?? -1000000;
      if (s >= threshold) {
        candidateMoves.add(m);
      }
    }
    if (candidateMoves.isNotEmpty) {
      return candidateMoves[ctx.rng.nextInt(candidateMoves.length)];
    }
  }

  // 3. Nước tốt nhất
  return bestMove;
}

int _negamax(_SearchContext ctx, int depth, int alpha, int beta, int ply) {
  if ((ctx.nodes & 2047) == 0) {
    ctx.checkTime();
  }
  if (ctx.stopSearch) return 0;

  if (ctx.isDraw(ply)) return 0;

  final key = ctx.board.zobristKey;
  final ttIdx = key & _TranspositionTable.mask;

  var ttMove = 0;
  if (ctx.config.useTranspositionTable && ctx.tt.keys[ttIdx] == key) {
    final entryDepth = ctx.tt.depths[ttIdx];
    final entryFlag = ctx.tt.flags[ttIdx];
    var entryScore = ctx.tt.scores[ttIdx];
    if (entryScore > 90000) {
      entryScore -= ply;
    } else if (entryScore < -90000) {
      entryScore += ply;
    }

    ttMove = ctx.tt.moves[ttIdx];

    if (entryDepth >= depth) {
      if (entryFlag == _ttExact) return entryScore;
      if (entryFlag == _ttLower && entryScore >= beta) return entryScore;
      if (entryFlag == _ttUpper && entryScore <= alpha) return entryScore;
    }
  }

  if (depth <= 0) {
    if (ctx.config.useQuiescence) {
      return _quiescence(ctx, alpha, beta, ply);
    }
    return Evaluation.evaluate(ctx.board);
  }

  final moves = <int>[];
  ctx.board.generateLegalMoves(moves);

  if (moves.isEmpty) {
    if (ctx.board.isInCheck()) {
      return -100000 + ply; // Checkmate
    }
    return 0; // Stalemate
  }

  ctx.sortMoves(moves, ttMove, ply);

  var bestScore = -1000000;
  var bestMoveThisNode = 0;
  final origAlpha = alpha;

  for (var i = 0; i < moves.length; i++) {
    final m = moves[i];
    ctx.searchStackKeys[ply] = key;
    ctx.board.makeMove(m);
    ctx.nodes++;

    final score = -_negamax(ctx, depth - 1, -beta, -alpha, ply + 1);
    ctx.board.unmakeMove();

    if (ctx.stopSearch) return 0;

    if (score > bestScore) {
      bestScore = score;
      bestMoveThisNode = m;
    }

    if (score > alpha) {
      alpha = score;
    }

    if (alpha >= beta) {
      // Beta cutoff (killer move)
      if ((m & SearchBoard.flagCapture) == 0 && SearchBoard.movePromo(m) == 0) {
        if (ctx.killer1[ply] != m) {
          ctx.killer2[ply] = ctx.killer1[ply];
          ctx.killer1[ply] = m;
        }
      }
      break;
    }
  }

  if (ctx.config.useTranspositionTable && !ctx.stopSearch) {
    var flag = _ttExact;
    if (bestScore <= origAlpha) {
      flag = _ttUpper;
    } else if (bestScore >= beta) {
      flag = _ttLower;
    }
    ctx.tt.store(key, bestMoveThisNode, bestScore, depth, flag, ply);
  }

  return bestScore;
}

int _quiescence(_SearchContext ctx, int alpha, int beta, int ply) {
  if ((ctx.nodes & 2047) == 0) {
    ctx.checkTime();
  }
  if (ctx.stopSearch) return 0;

  var bestValue = Evaluation.evaluate(ctx.board);
  if (bestValue >= beta) return beta;
  if (bestValue > alpha) alpha = bestValue;

  final captures = <int>[];
  ctx.board.generateCaptures(captures);
  if (captures.isEmpty) return bestValue;

  ctx.sortMoves(captures, 0, ply);

  for (var i = 0; i < captures.length; i++) {
    final m = captures[i];
    ctx.board.makeMove(m);
    ctx.nodes++;

    final score = -_quiescence(ctx, -beta, -alpha, ply + 1);
    ctx.board.unmakeMove();

    if (ctx.stopSearch) return 0;

    if (score > bestValue) {
      bestValue = score;
    }
    if (bestValue >= beta) return beta;
    if (bestValue > alpha) alpha = bestValue;
  }

  return bestValue;
}
