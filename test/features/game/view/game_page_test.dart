import 'dart:async';

import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/game/widgets/promotion_dialog.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/features/settings/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  Future<void> pumpGame(
    WidgetTester tester, {
    GamePosition? startPosition,
    GameConfig? config,
    ChessAi? ai,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settingsRepo = InMemorySettingsRepository();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SoundPlayer>.value(value: MockSoundPlayer()),
          RepositoryProvider<ChessAi>.value(value: ai ?? MockChessAi()),
          RepositoryProvider<SettingsRepository>.value(value: settingsRepo),
        ],
        child: BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(repository: settingsRepo),
          child: MaterialApp(
            home: GamePage(
              config: config ?? const GameConfig.pvp(),
              startPosition: startPosition,
            ),
          ),
        ),
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
      expect(
        find.descendant(
          of: find.byType(PromotionDialog),
          matching: find.byType(PieceView),
        ),
        findsNWidgets(4),
      );

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

  testWidgets(
    'undo button is disabled at start, enabled after 1 move, and reverts board on tap',
    (tester) async {
      await pumpGame(tester);

      final undoButton = find.widgetWithIcon(IconButton, Icons.undo);
      expect(undoButton, findsOneWidget);

      // Ban đầu bị disable
      expect(tester.widget<IconButton>(undoButton).onPressed, isNull);

      // Đi 1 nước: e2 -> e4
      await tapSquare(tester, 'e2');
      await tapSquare(tester, 'e4');
      await tester.pump();

      // Nút được enable
      expect(tester.widget<IconButton>(undoButton).onPressed, isNotNull);
      expect(pieceAt(tester, 'e2'), isNull);
      expect(pieceAt(tester, 'e4'), 'P');

      // Bấm nút đi lại
      await tester.tap(undoButton);
      await tester.pump();

      // Bàn cờ trở lại thế ban đầu, nút lại bị disable
      expect(pieceAt(tester, 'e2'), 'P');
      expect(pieceAt(tester, 'e4'), isNull);
      expect(tester.widget<IconButton>(undoButton).onPressed, isNull);
      expect(find.text('Lượt đi: Trắng'), findsOneWidget);
    },
  );

  testWidgets(
    'PvE when human plays Black flips board (white pieces at top) and shows AI thinking indicator',
    (tester) async {
      final aiCompleter = Completer<Move>();
      final mockAi = MockChessAi();
      when(() => mockAi.chooseMove(any(), any()))
          .thenAnswer((_) => aiCompleter.future);

      await pumpGame(
        tester,
        config: const GameConfig(
          mode: GameMode.pve,
          humanColor: PieceColor.black,
        ),
        ai: mockAi,
      );
      await tester.pump();

      // Máy đi trước -> hiển thị Máy đang nghĩ... kèm spinner 16
      expect(find.text('Máy đang nghĩ…'), findsOneWidget);
      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      final spinnerBox = tester.widget<SizedBox>(
        find.ancestor(of: spinner, matching: find.byType(SizedBox)).first,
      );
      expect(spinnerBox.width, 16);
      expect(spinnerBox.height, 16);

      // Bàn cờ lật: quân trắng nằm ở phía trên (y nhỏ hơn quân đen)
      final whiteKingPos = tester.getCenter(
        find.byWidgetPredicate((w) => w is PieceView && w.piece == 'K'),
      );
      final blackKingPos = tester.getCenter(
        find.byWidgetPredicate((w) => w is PieceView && w.piece == 'k'),
      );
      expect(whiteKingPos.dy, lessThan(blackKingPos.dy));

      // Máy hoàn thành nước đi
      aiCompleter.complete(const Move(52, 36)); // e2e4
      await tester.pump();

      expect(find.text('Máy đang nghĩ…'), findsNothing);
      expect(find.text('Lượt đi: Đen'), findsOneWidget);
    },
  );

  testWidgets(
    'resigning: cancel in dialog changes nothing; confirm sets result text and disables buttons',
    (tester) async {
      await pumpGame(tester);
      await tester.pump();

      final resignButton = find.widgetWithIcon(IconButton, Icons.flag);
      final undoButton = find.widgetWithIcon(IconButton, Icons.undo);

      expect(tester.widget<IconButton>(resignButton).onPressed, isNotNull);
      expect(find.text('Lượt đi: Trắng'), findsOneWidget);

      // Bấm nút Đầu hàng -> hiện dialog
      await tester.tap(resignButton);
      await tester.pumpAndSettle();

      expect(find.text('Đầu hàng?'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);

      // Bấm Hủy -> dialog đóng, ván cờ không đổi
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.text('Đầu hàng?'), findsNothing);
      expect(find.text('Lượt đi: Trắng'), findsOneWidget);
      expect(tester.widget<IconButton>(resignButton).onPressed, isNotNull);

      // Bấm Đầu hàng lần nữa và xác nhận
      await tester.tap(resignButton);
      await tester.pumpAndSettle();

      final confirmButton = find.widgetWithText(TextButton, 'Đầu hàng');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Kết quả đúng: Trắng đầu hàng - Đen thắng
      expect(find.text('Trắng đầu hàng - Đen thắng'), findsOneWidget);

      // Nút Đầu hàng và nút Đi lại bị disable
      expect(tester.widget<IconButton>(resignButton).onPressed, isNull);
      expect(tester.widget<IconButton>(undoButton).onPressed, isNull);
    },
  );

  testWidgets(
    'resigning on Black turn sets "Đen đầu hàng - Trắng thắng" and disables buttons',
    (tester) async {
      await pumpGame(tester);
      await tester.pump();

      final resignButton = find.widgetWithIcon(IconButton, Icons.flag);
      final undoButton = find.widgetWithIcon(IconButton, Icons.undo);

      // Đi e2 -> e4 để chuyển lượt sang Đen
      await tapSquare(tester, 'e2');
      await tapSquare(tester, 'e4');
      expect(find.text('Lượt đi: Đen'), findsOneWidget);
      expect(tester.widget<IconButton>(undoButton).onPressed, isNotNull);

      // Bấm Đầu hàng và xác nhận
      await tester.tap(resignButton);
      await tester.pumpAndSettle();

      final confirmButton = find.widgetWithText(TextButton, 'Đầu hàng');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Kết quả đúng: Đen đầu hàng - Trắng thắng
      expect(find.text('Đen đầu hàng - Trắng thắng'), findsOneWidget);

      // Cả nút Đầu hàng và Đi lại đều bị disable
      expect(tester.widget<IconButton>(resignButton).onPressed, isNull);
      expect(tester.widget<IconButton>(undoButton).onPressed, isNull);
    },
  );

  testWidgets('tapping settings button on GamePage navigates to SettingsPage', (
    tester,
  ) async {
    await pumpGame(tester);

    final settingsButton = find.byTooltip('Cài đặt');
    expect(settingsButton, findsOneWidget);

    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
  });
}
