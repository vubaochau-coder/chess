import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  Future<void> pumpGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<SoundPlayer>.value(
        value: MockSoundPlayer(),
        child: const MaterialApp(home: GamePage()),
      ),
    );
  }

  /// Tâm của ô theo tên (vd. 'e2') trên màn hình.
  Offset squareCenter(WidgetTester tester, String name) {
    final board = tester.getRect(find.byType(ChessBoard));
    final cell = board.width / 8;
    final col = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(name[1]);
    return board.topLeft + Offset((col + .5) * cell, (row + .5) * cell);
  }

  Future<void> tapSquare(WidgetTester tester, String name) async {
    await tester.tapAt(squareCenter(tester, name));
    await tester.pump();
  }

  String? pieceAt(WidgetTester tester, String name) {
    final center = squareCenter(tester, name);
    for (final element in find.byType(PieceView).evaluate()) {
      if (tester.getRect(find.byWidget(element.widget)).contains(center)) {
        return (element.widget as PieceView).piece;
      }
    }
    return null;
  }

  testWidgets('renders the starting position', (tester) async {
    await pumpGame(tester);

    expect(find.text('Lượt đi: Trắng'), findsOneWidget);
    expect(find.byType(PieceView), findsNWidgets(32));
    expect(pieceAt(tester, 'e1'), 'K');
    expect(pieceAt(tester, 'd8'), 'q');
  });

  testWidgets('tapping e2 then e4 moves the pawn and passes the turn', (
    tester,
  ) async {
    await pumpGame(tester);

    await tapSquare(tester, 'e2');
    await tapSquare(tester, 'e4');

    expect(pieceAt(tester, 'e2'), isNull);
    expect(pieceAt(tester, 'e4'), 'P');
    expect(find.text('Lượt đi: Đen'), findsOneWidget);
  });

  testWidgets('new game button resets the board', (tester) async {
    await pumpGame(tester);
    await tapSquare(tester, 'e2');
    await tapSquare(tester, 'e4');

    await tester.tap(find.text('Ván mới'));
    await tester.pump();

    expect(pieceAt(tester, 'e2'), 'P');
    expect(find.text('Lượt đi: Trắng'), findsOneWidget);
  });
}
