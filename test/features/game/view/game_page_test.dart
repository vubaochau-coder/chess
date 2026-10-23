import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/game/widgets/promotion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  Future<void> pumpGame(
    WidgetTester tester, {
    GamePosition? startPosition,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<SoundPlayer>.value(
        value: MockSoundPlayer(),
        child: MaterialApp(home: GamePage(startPosition: startPosition)),
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

  testWidgets('displays draw status text when threefold repetition occurs', (
    tester,
  ) async {
    await pumpGame(tester);

    // 1. Nf3 Nf6
    await tapSquare(tester, 'g1');
    await tapSquare(tester, 'f3');
    await tapSquare(tester, 'g8');
    await tapSquare(tester, 'f6');

    // 2. Ng1 Ng8
    await tapSquare(tester, 'f3');
    await tapSquare(tester, 'g1');
    await tapSquare(tester, 'f6');
    await tapSquare(tester, 'g8');

    // 3. Nf3 Nf6
    await tapSquare(tester, 'g1');
    await tapSquare(tester, 'f3');
    await tapSquare(tester, 'g8');
    await tapSquare(tester, 'f6');

    // 4. Ng1 Ng8 (repetition 3rd time)
    await tapSquare(tester, 'f3');
    await tapSquare(tester, 'g1');
    await tapSquare(tester, 'f6');
    await tapSquare(tester, 'g8');

    expect(find.text('Hòa - lặp lại 3 lần'), findsOneWidget);
  });

  testWidgets(
    'pawn reaches last rank shows promotion dialog and selecting Knight promotes to N',
    (tester) async {
      await pumpGame(
        tester,
        startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
      );

      await tapSquare(tester, 'a7');
      await tapSquare(tester, 'a8');
      await tester.pumpAndSettle();

      expect(find.byType(PromotionDialog), findsOneWidget);
      expect(find.text('Phong cấp'), findsOneWidget);

      // 4 choices: Q, R, B, N
      final knightButton = find.descendant(
        of: find.byType(PromotionDialog),
        matching: find.byWidgetPredicate(
          (w) => w is PieceView && w.piece == 'N',
        ),
      );
      expect(knightButton, findsOneWidget);

      await tester.tap(knightButton);
      await tester.pumpAndSettle();

      expect(find.byType(PromotionDialog), findsNothing);
      expect(pieceAt(tester, 'a8'), 'N');
      expect(pieceAt(tester, 'a7'), isNull);
    },
  );

  testWidgets('pawn reaches last rank and tapping outside cancels promotion', (
    tester,
  ) async {
    await pumpGame(
      tester,
      startPosition: Fen.parse('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
    );

    await tapSquare(tester, 'a7');
    await tapSquare(tester, 'a8');
    await tester.pumpAndSettle();

    expect(find.byType(PromotionDialog), findsOneWidget);

    // Tap outside dialog to dismiss
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(PromotionDialog), findsNothing);
    expect(pieceAt(tester, 'a7'), 'P');
    expect(pieceAt(tester, 'a8'), isNull);
  });

  testWidgets(
    'displays move list and captured pieces with material advantage',
    (tester) async {
      await pumpGame(tester);

      // 1. e4 d5
      await tapSquare(tester, 'e2');
      await tapSquare(tester, 'e4');
      await tapSquare(tester, 'd7');
      await tapSquare(tester, 'd5');

      expect(find.text('1. e4'), findsOneWidget);
      expect(find.text('d5'), findsOneWidget);

      // 2. exd5 (White captures black pawn)
      await tapSquare(tester, 'e4');
      await tapSquare(tester, 'd5');

      expect(find.text('2. exd5'), findsOneWidget);
      // White has captured 1 pawn (+1 material advantage for White)
      expect(find.text('+1'), findsOneWidget);

      // 2... Qxd5 (Black captures white pawn)
      await tapSquare(tester, 'd8');
      await tapSquare(tester, 'd5');

      expect(find.text('Qxd5'), findsOneWidget);
      // Material is now equal (each captured 1 pawn), so +N should not be shown
      expect(find.text('+1'), findsNothing);
    },
  );
}
