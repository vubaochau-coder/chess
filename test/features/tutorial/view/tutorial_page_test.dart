import 'package:chess/core/engine/square.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/core/storage/tutorial_progress_repository.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/features/tutorial/view/lesson_page.dart';
import 'package:chess/features/tutorial/view/tutorial_page.dart';
import 'package:chess/features/tutorial/widgets/lesson_board_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryTutorialProgressRepository repository;

  Future<void> pumpTutorial(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = InMemoryTutorialProgressRepository();
    await tester.pumpWidget(
      RepositoryProvider<TutorialProgressRepository>.value(
        value: repository,
        child: BlocProvider<SettingsCubit>(
          create: (_) =>
              SettingsCubit(repository: InMemorySettingsRepository()),
          child: const MaterialApp(home: TutorialPage()),
        ),
      ),
    );
  }

  Future<void> tapSquare(WidgetTester tester, String name) async {
    final board = tester.getRect(find.byType(LessonBoardView));
    final cell = board.width / 8;
    final square = squareFromName(name);
    final x = (square % 8 + 0.5) * cell;
    final y = (square ~/ 8 + 0.5) * cell;
    await tester.tapAt(board.topLeft + Offset(x, y));
    await tester.pump();
  }

  Future<void> movePiece(WidgetTester tester, String from, String to) async {
    await tapSquare(tester, from);
    await tapSquare(tester, to);
  }

  testWidgets('lists chapters, lessons and progress', (tester) async {
    await pumpTutorial(tester);

    expect(find.text('Học chơi cờ'), findsOneWidget);
    expect(find.text('0/17 bài'), findsOneWidget);
    expect(find.text('CHƯƠNG 1 · CÁC QUÂN CỜ'), findsOneWidget);
    expect(find.text('CHƯƠNG 4 · MẸO CƠ BẢN'), findsOneWidget);
    expect(find.text('Mã'), findsOneWidget);
    expect(find.text('Bảo vệ Vua'), findsOneWidget);
  });

  testWidgets('completing the knight challenge updates progress', (
    tester,
  ) async {
    await pumpTutorial(tester);

    await tester.tap(find.text('Mã'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonPage), findsOneWidget);

    final next = find.widgetWithText(FilledButton, 'Bài tiếp: Tốt');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);

    await movePiece(tester, 'b1', 'c3');
    await movePiece(tester, 'c3', 'e4');
    await movePiece(tester, 'e4', 'g5');

    expect(
      find.text('Tuyệt vời! Bạn đã hoàn thành thử thách.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    expect(repository.load(), {'knight'});

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('1/17 bài'), findsOneWidget);
  });

  testWidgets('a wrong move fails the challenge and Làm lại resets it', (
    tester,
  ) async {
    await pumpTutorial(tester);

    await tester.tap(find.text('Tốt'));
    await tester.pumpAndSettle();

    await movePiece(tester, 'e4', 'e5');
    expect(
      find.text('Chưa đúng rồi. Bấm Làm lại để thử lần nữa nhé.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Làm lại'));
    await tester.pump();
    await movePiece(tester, 'e4', 'd5');

    expect(
      find.text('Tuyệt vời! Bạn đã hoàn thành thử thách.'),
      findsOneWidget,
    );
  });

  testWidgets('Bài tiếp opens the next lesson', (tester) async {
    await pumpTutorial(tester);

    await tester.tap(find.text('Bàn cờ và cách xếp quân'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Bài tiếp: Vua'));
    await tester.pumpAndSettle();

    expect(find.text('Vua'), findsOneWidget);
    expect(repository.load(), {'board'});
  });
}
