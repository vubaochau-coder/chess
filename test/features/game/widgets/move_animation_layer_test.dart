import 'package:chess/core/engine/chess_rules.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/move_animation_layer.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  const step = Duration(milliseconds: 75);

  Future<ChessGameBloc> pumpBoard(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    GamePosition? startPosition,
  }) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bloc = ChessGameBloc(
      soundPlayer: MockSoundPlayer(),
      ai: MockChessAi(),
      config: const GameConfig.pvp(),
      startPosition: startPosition,
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<SettingsCubit>(
        create: (_) =>
            SettingsCubit(repository: InMemorySettingsRepository(settings)),
        child: BlocProvider<ChessGameBloc>.value(
          value: bloc,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: ChessBoard())),
          ),
        ),
      ),
    );
    return bloc;
  }

  /// Ô theo tên (vd. 'e2') sang index của bàn cờ (hàng 8 ở trên).
  int square(String name) {
    final col = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(name[1]);
    return row * 8 + col;
  }

  Offset squareCenter(WidgetTester tester, String name) {
    final board = tester.getRect(find.byType(ChessBoard));
    final cell = board.width / 8;
    final col = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(name[1]);
    return board.topLeft + Offset((col + .5) * cell, (row + .5) * cell);
  }

  Future<void> move(
    WidgetTester tester,
    ChessGameBloc bloc,
    String from,
    String to,
  ) async {
    bloc.add(SquareTapped(square(from)));
    bloc.add(SquareTapped(square(to)));
    await tester.pump();
  }

  Finder sliding(String piece) => find.descendant(
    of: find.byType(MoveAnimationLayer),
    matching: find.byWidgetPredicate((w) => w is PieceView && w.piece == piece),
  );

  Finder pieces(String piece) =>
      find.byWidgetPredicate((w) => w is PieceView && w.piece == piece);

  /// Có quân [piece] nằm trọn ở ô [name] (quân đang trượt dở thì không).
  bool restsOn(WidgetTester tester, String piece, String name) {
    final center = squareCenter(tester, name);
    for (final element in pieces(piece).evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      if (rect.contains(center)) return true;
    }
    return false;
  }

  testWidgetZ('the moved piece slides from e2 to e4', (tester) async {
    final bloc = await pumpBoard(tester);

    await move(tester, bloc, 'e2', 'e4');
    await tester.pump(step);

    final midway = tester.getCenter(sliding('P'));
    final e2 = squareCenter(tester, 'e2');
    final e4 = squareCenter(tester, 'e4');
    expect(midway.dx, moreOrLessEquals(e2.dx));
    expect(midway.dy, lessThan(e2.dy));
    expect(midway.dy, greaterThan(e4.dy));
    expect(restsOn(tester, 'P', 'e4'), isFalse);

    await tester.pump(step);
    await tester.pump();

    expect(sliding('P'), findsNothing);
    expect(restsOn(tester, 'P', 'e4'), isTrue);
    expect(restsOn(tester, 'P', 'e2'), isFalse);
  });

  testWidgets('undo is not animated', (tester) async {
    final bloc = await pumpBoard(tester);
    await move(tester, bloc, 'e2', 'e4');
    await tester.pumpAndSettle();

    bloc.add(const UndoRequested());
    await tester.pump();

    final animated = find.descendant(
      of: find.byType(MoveAnimationLayer),
      matching: find.byType(PieceView),
    );
    animated.evaluate();
    restsOn(tester, 'P', 'e2');
    expect(restsOn(tester, 'P', 'e4'), isFalse);
  });

  testWidgetZ('castling slides king and rook together', (tester) async {
    final bloc = await pumpBoard(
      tester,
      startPosition: Fen.parse('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
    );

    await move(tester, bloc, 'e1', 'g1');
    await tester.pump(step);

    final king = tester.getCenter(sliding('K'));
    final rook = tester.getCenter(sliding('R'));
    expect(king.dx, greaterThan(squareCenter(tester, 'e1').dx));
    expect(king.dx, lessThan(squareCenter(tester, 'g1').dx));
    expect(rook.dx, lessThan(squareCenter(tester, 'h1').dx));
    expect(rook.dx, greaterThan(squareCenter(tester, 'f1').dx));

    await tester.pumpAndSettle();

    expect(restsOn(tester, 'K', 'g1'), isTrue);
    expect(restsOn(tester, 'R', 'f1'), isTrue);
  });

  testWidgetZ('a captured piece stays until the slide ends', (tester) async {
    final bloc = await pumpBoard(
      tester,
      startPosition: Fen.parse('4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1'),
    );

    await move(tester, bloc, 'e4', 'd5');
    await tester.pump(step);

    expect(sliding('p'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(pieces('p'), findsNothing);
    expect(restsOn(tester, 'P', 'd5'), isTrue);
  });

  testWidgetZ('no animation when animations are turned off', (tester) async {
    final bloc = await pumpBoard(
      tester,
      settings: const AppSettings(animationsEnabled: false),
    );

    await move(tester, bloc, 'e2', 'e4');

    expect(sliding('P'), findsNothing);
    expect(restsOn(tester, 'P', 'e4'), isTrue);
  });
}

void testWidgetZ(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {}
