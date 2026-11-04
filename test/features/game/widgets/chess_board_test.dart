import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/features/game/bloc/chess_game_bloc.dart';
import 'package:chess/features/game/painter/board_painter.dart';
import 'package:chess/features/game/painter/highlight_painter.dart';
import 'package:chess/features/game/widgets/chess_board.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:chess/theme/piece_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('ChessBoard theme integration', () {
    testWidgets('changing boardTheme in SettingsCubit updates painter colors', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final settingsRepo = InMemorySettingsRepository(
        const AppSettings(boardTheme: BoardTheme.wood),
      );
      final settingsCubit = SettingsCubit(repository: settingsRepo);

      await tester.pumpWidget(
        BlocProvider<SettingsCubit>.value(
          value: settingsCubit,
          child: BlocProvider<ChessGameBloc>(
            create: (_) => ChessGameBloc(
              soundPlayer: MockSoundPlayer(),
              ai: MockChessAi(),
              config: const GameConfig.pvp(),
            ),
            child: const MaterialApp(home: Scaffold(body: ChessBoard())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify BoardPainter has wood colors initially
      final boardPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is BoardPainter,
      );
      expect(boardPaintFinder, findsOneWidget);
      BoardPainter boardPainter =
          (tester.widget<CustomPaint>(boardPaintFinder).painter!)
              as BoardPainter;
      expect(boardPainter.colors, equals(BoardTheme.wood.colors));

      // Verify HighlightPainter has wood colors initially
      final highlightPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is HighlightPainter,
      );
      expect(highlightPaintFinder, findsOneWidget);
      HighlightPainter highlightPainter =
          (tester.widget<CustomPaint>(highlightPaintFinder).painter!)
              as HighlightPainter;
      expect(highlightPainter.colors, equals(BoardTheme.wood.colors));

      // Change theme to blue
      settingsCubit.setBoardTheme(BoardTheme.blue);
      await tester.pumpAndSettle();

      // Verify BoardPainter receives blue colors
      boardPainter =
          (tester.widget<CustomPaint>(boardPaintFinder).painter!)
              as BoardPainter;
      expect(boardPainter.colors, equals(BoardTheme.blue.colors));

      // Verify HighlightPainter receives blue colors
      highlightPainter =
          (tester.widget<CustomPaint>(highlightPaintFinder).painter!)
              as HighlightPainter;
      expect(highlightPainter.colors, equals(BoardTheme.blue.colors));
    });

    testWidgets('changing pieceSet mid-game keeps the position', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final settingsCubit = SettingsCubit(
        repository: InMemorySettingsRepository(),
      );
      final gameBloc = ChessGameBloc(
        soundPlayer: MockSoundPlayer(),
        ai: MockChessAi(),
        config: const GameConfig.pvp(),
      );
      addTearDown(gameBloc.close);

      await tester.pumpWidget(
        BlocProvider<SettingsCubit>.value(
          value: settingsCubit,
          child: BlocProvider<ChessGameBloc>.value(
            value: gameBloc,
            child: const MaterialApp(home: Scaffold(body: ChessBoard())),
          ),
        ),
      );

      // e2-e4
      gameBloc
        ..add(const SquareTapped(52))
        ..add(const SquareTapped(36));
      await tester.pumpAndSettle();
      final position = gameBloc.state.position;
      expect(position.board[36], 'P');

      settingsCubit.setPieceSet(PieceSet.flat);
      await tester.pumpAndSettle();

      expect(gameBloc.state.position, same(position));
      final pieces = tester.widgetList<PieceView>(find.byType(PieceView));
      expect(pieces, hasLength(32));
      expect(pieces.every((p) => p.pieceSet == PieceSet.flat), isTrue);
      final assets = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .map((svg) => (svg.bytesLoader as SvgAssetLoader).assetName)
          .toSet();
      expect(assets, contains('assets/pieces/flat/wP.svg'));
      expect(assets, hasLength(12));
    });
  });
}
