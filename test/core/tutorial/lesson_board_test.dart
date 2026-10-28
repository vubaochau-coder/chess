import 'package:chess/core/engine/square.dart';
import 'package:chess/core/tutorial/lesson.dart';
import 'package:chess/core/tutorial/lesson_board.dart';
import 'package:chess/core/tutorial/lesson_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

Lesson _lesson(String id) =>
    LessonCatalog.lessons.firstWhere((lesson) => lesson.id == id);

/// Đi một nước bằng hai lần chạm, như người chơi.
LessonBoard _play(LessonBoard board, String from, String to) =>
    board.tap(squareFromName(from)).tap(squareFromName(to));

void main() {
  group('LessonBoard', () {
    test('tapping a white piece selects it and lists its moves', () {
      final board = LessonBoard.start(_lesson('knight'));
      final selected = board.tap(squareFromName('b1'));

      final expected = [
        squareFromName('a3'),
        squareFromName('c3'),
        squareFromName('d2'),
      ];
      expect(selected.selected, squareFromName('b1'));
      expect(selected.targets, unorderedEquals(expected));
    });

    test('tapping a black piece does not select it', () {
      final board = LessonBoard.start(_lesson('knight'));

      expect(board.tap(squareFromName('a8')).selected, isNull);
    });

    test('reach: success when the piece lands on the target', () {
      var board = LessonBoard.start(_lesson('knight'));
      board = _play(board, 'b1', 'c3');
      expect(board.result, LessonResult.playing);
      expect(board.position.whiteToMove, isTrue);
      board = _play(board, 'c3', 'e4');
      board = _play(board, 'e4', 'g5');

      expect(board.result, LessonResult.success);
      expect(board.movesMade, 3);
    });

    test('reach: failed after using all moves', () {
      var board = LessonBoard.start(_lesson('knight'));
      board = _play(board, 'b1', 'a3');
      board = _play(board, 'a3', 'b1');
      board = _play(board, 'b1', 'a3');

      expect(board.result, LessonResult.failed);
    });

    test('finished board ignores further taps', () {
      var board = LessonBoard.start(_lesson('queen'));
      board = _play(board, 'd1', 'h5');
      expect(board.result, LessonResult.success);

      expect(board.tap(squareFromName('e1')), board);
    });

    test('giveCheck: success on check, failed otherwise', () {
      final board = LessonBoard.start(_lesson('check'));

      expect(_play(board, 'a1', 'a8').result, LessonResult.success);
      expect(_play(board, 'a1', 'a2').result, LessonResult.failed);
    });

    test('checkmate: success on mate, failed on a plain check', () {
      final board = LessonBoard.start(_lesson('checkmate'));

      expect(_play(board, 'a1', 'a8').result, LessonResult.success);
      expect(_play(board, 'a1', 'a2').result, LessonResult.failed);
    });

    test('playMove: castling is accepted, other moves are not', () {
      final board = LessonBoard.start(_lesson('castling'));

      final castled = _play(board, 'e1', 'g1');
      expect(castled.result, LessonResult.success);
      expect(castled.position.board[squareFromName('f1')], 'R');
      expect(_play(board, 'e1', 'f1').result, LessonResult.failed);
    });

    test('playMove: promotion turns the pawn into a queen', () {
      final board = _play(LessonBoard.start(_lesson('promotion')), 'e7', 'e8');

      expect(board.result, LessonResult.success);
      expect(board.position.board[squareFromName('e8')], 'Q');
    });

    test('lesson without challenge keeps playing with White to move', () {
      var board = LessonBoard.start(_lesson('board'));
      board = _play(board, 'e2', 'e4');
      board = _play(board, 'd2', 'd4');

      expect(board.result, LessonResult.playing);
      expect(board.position.board[squareFromName('d4')], 'P');
    });
  });
}
