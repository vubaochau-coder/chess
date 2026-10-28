import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/engine/square.dart';
import 'package:chess/core/tutorial/lesson.dart';
import 'package:chess/core/tutorial/lesson_board.dart';
import 'package:chess/core/tutorial/lesson_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thử mọi chuỗi nước đi của Trắng, tối đa [depth] nước.
bool _canSucceed(LessonBoard board, int depth) {
  if (board.result == LessonResult.success) return true;
  if (board.result == LessonResult.failed || depth == 0) return false;
  for (var from = 0; from < 64; from++) {
    final selected = board.tap(from);
    for (final to in selected.targets) {
      if (_canSucceed(selected.tap(to), depth - 1)) return true;
    }
  }
  return false;
}

void main() {
  group('LessonCatalog', () {
    test('has 17 lessons in 4 chapters with unique ids', () {
      expect(LessonCatalog.chapters, hasLength(4));
      expect(LessonCatalog.lessons, hasLength(17));
      final ids = LessonCatalog.lessons.map((l) => l.id).toSet();
      expect(ids, hasLength(17));
    });

    for (final lesson in LessonCatalog.lessons) {
      test('${lesson.id}: position is valid with White to move', () {
        final position = Fen.parse(lesson.fen);
        expect(position.whiteToMove, isTrue);
        expect(position.board.where((p) => p == 'K'), hasLength(1));
        expect(position.board.where((p) => p == 'k'), hasLength(1));
        expect(ChessRules.isInCheck(position.board, true), isFalse);
        expect(lesson.chapter, inInclusiveRange(0, 3));
        expect(lesson.body, isNotEmpty);
        for (final name in lesson.highlights) {
          expect(() => squareFromName(name), returnsNormally);
        }
      });

      final challenge = lesson.challenge;
      if (challenge == null) continue;

      test('${lesson.id}: challenge can be solved', () {
        final board = LessonBoard.start(lesson);
        expect(_canSucceed(board, challenge.maxMoves), isTrue);
      });

      if (challenge.kind == ChallengeKind.playMove) {
        test('${lesson.id}: accepted moves are legal', () {
          final position = Fen.parse(lesson.fen);
          for (final uci in challenge.acceptedMoves) {
            final move = Move.fromUci(uci);
            final targets = ChessRules.legalMoves(position, move.from);
            expect(targets, contains(move.to), reason: uci);
          }
        });
      }
    }
  });
}
