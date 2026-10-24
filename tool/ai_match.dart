import 'dart:io';

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/search.dart';
import 'package:chess/core/engine/chess_rules.dart';

enum GameWinner { white, black, draw }

final class GameResult {
  const GameResult({
    required this.winner,
    required this.movesCount,
    required this.endStatus,
    required this.reason,
  });

  final GameWinner winner;
  final int movesCount;
  final GameStatus? endStatus;
  final String reason;
}

GameResult playGame(
  AiLevel whiteLevel,
  AiLevel blackLevel, {
  int maxMoves = 150,
}) {
  final history = <GamePosition>[GamePosition.initial()];
  var movesCount = 0;

  while (movesCount < maxMoves) {
    final status = ChessRules.gameStatus(history);
    if (status.isGameOver) {
      if (status == GameStatus.checkmate) {
        // Bên tới lượt đi bị chiếu hết -> bên kia thắng
        final winner = history.last.whiteToMove
            ? GameWinner.black
            : GameWinner.white;
        return GameResult(
          winner: winner,
          movesCount: movesCount,
          endStatus: status,
          reason: 'Checkmate',
        );
      }
      return GameResult(
        winner: GameWinner.draw,
        movesCount: movesCount,
        endStatus: status,
        reason: status.name,
      );
    }

    final currentLevel = history.last.whiteToMove ? whiteLevel : blackLevel;
    final searchResult = search(history, currentLevel.config);
    final move = searchResult.bestMove;

    final moveResult = move.promotion != null
        ? ChessRules.applyMove(
            history.last,
            move.from,
            move.to,
            promotion: move.promotion!,
          )
        : ChessRules.applyMove(history.last, move.from, move.to);

    history.add(moveResult.position);
    movesCount++;
  }

  // Quá số nước tối đa -> hòa
  final finalStatus = ChessRules.gameStatus(history);
  return GameResult(
    winner: GameWinner.draw,
    movesCount: movesCount,
    endStatus: finalStatus,
    reason: 'Đạt giới hạn $maxMoves nước',
  );
}

void runSeries(AiLevel highLevel, AiLevel lowLevel, int totalGames) {
  stdout.writeln(
    '================================================================',
  );
  stdout.writeln(
    'Bắt đầu trận đấu: ${highLevel.name} vs ${lowLevel.name} ($totalGames ván, tối đa 150 nước/ván)',
  );
  stdout.writeln(
    '================================================================',
  );

  var highWins = 0;
  var lowWins = 0;
  var draws = 0;

  final swTotal = Stopwatch()..start();

  for (var i = 1; i <= totalGames; i++) {
    final highIsWhite = (i % 2 == 1);
    final whiteLevel = highIsWhite ? highLevel : lowLevel;
    final blackLevel = highIsWhite ? lowLevel : highLevel;

    final whiteLabel = highIsWhite ? highLevel.name : lowLevel.name;
    final blackLabel = highIsWhite ? lowLevel.name : highLevel.name;

    stdout.write(
      'Ván $i/$totalGames: [Trắng: $whiteLabel] vs [Đen: $blackLabel]... ',
    );

    final swGame = Stopwatch()..start();
    final result = playGame(whiteLevel, blackLevel);
    swGame.stop();

    if (result.winner == GameWinner.draw) {
      draws++;
      stdout.writeln(
        'Hòa (${result.reason}, ${result.movesCount} nước, ${swGame.elapsed.inSeconds}s)',
      );
    } else {
      final highWon =
          (highIsWhite && result.winner == GameWinner.white) ||
          (!highIsWhite && result.winner == GameWinner.black);
      if (highWon) {
        highWins++;
        stdout.writeln(
          '${highLevel.name} thắng! (${result.reason}, ${result.movesCount} nước, ${swGame.elapsed.inSeconds}s)',
        );
      } else {
        lowWins++;
        stdout.writeln(
          '${lowLevel.name} thắng! (${result.reason}, ${result.movesCount} nước, ${swGame.elapsed.inSeconds}s)',
        );
      }
    }
  }

  swTotal.stop();
  stdout.writeln('------------------------------------------------');
  stdout.writeln('TỔNG KẾT (${highLevel.name} vs ${lowLevel.name}):');
  stdout.writeln('  ${highLevel.name} thắng: $highWins');
  stdout.writeln('  ${lowLevel.name} thắng: $lowWins');
  stdout.writeln('  Hòa: $draws');
  stdout.writeln('  Tỉ số: $highWins - $draws - $lowWins');
  stdout.writeln('  Thời gian: ${swTotal.elapsed.inSeconds}s');
  final winRate = (highWins / totalGames * 100).toStringAsFixed(1);
  stdout.writeln('  Tỉ lệ thắng của ${highLevel.name}: $winRate%');
  stdout.writeln('------------------------------------------------\n');
}

void main(List<String> args) {
  final pair = args.isNotEmpty ? args.first : 'all';

  if (pair == 'medium-easy' || pair == 'all') {
    runSeries(AiLevel.medium, AiLevel.easy, 10);
  }

  if (pair == 'hard-medium' || pair == 'all') {
    runSeries(AiLevel.hard, AiLevel.medium, 10);
  }
}
