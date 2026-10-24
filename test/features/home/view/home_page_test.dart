import 'dart:math' as math;

import 'package:chess/core/ai/ai_level.dart';
import 'package:chess/core/ai/chess_ai.dart';
import 'package:chess/core/audio/sound_player.dart';
import 'package:chess/core/engine/fen.dart';
import 'package:chess/core/engine/move.dart';
import 'package:chess/core/game/game_config.dart';
import 'package:chess/core/storage/game_repository.dart';
import 'package:chess/core/storage/saved_game.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/features/game/view/game_page.dart';
import 'package:chess/features/home/view/home_page.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/features/settings/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

class _FixedRandom implements math.Random {
  _FixedRandom(this.nextBoolValue);

  final bool nextBoolValue;

  @override
  bool nextBool() => nextBoolValue;

  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;
}

void main() {
  late MockSoundPlayer sound;
  late MockChessAi ai;
  late MockGameRepository repo;

  setUpAll(registerFallbacks);

  setUp(() {
    sound = MockSoundPlayer();
    ai = MockChessAi();
    repo = MockGameRepository();
    when(() => ai.chooseMove(any(), any()))
        .thenAnswer((_) async => const Move(52, 36));
    when(repo.load).thenReturn(null);
    when(() => repo.save(any())).thenAnswer((_) async {});
    when(repo.clear).thenAnswer((_) async {});
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    math.Random? random,
    GameRepository? gameRepository,
    Key? key,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    final settingsRepo = InMemorySettingsRepository();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SoundPlayer>.value(value: sound),
          RepositoryProvider<ChessAi>.value(value: ai),
          RepositoryProvider<GameRepository>.value(
            value: gameRepository ?? repo,
          ),
          RepositoryProvider<SettingsRepository>.value(value: settingsRepo),
        ],
        child: BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(repository: settingsRepo),
          child: MaterialApp(
            home: HomePage(key: key, random: random),
          ),
        ),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('renders initial elements in PvE mode by default', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.text('Cờ vua'), findsOneWidget);
      expect(find.text('Chơi với máy'), findsOneWidget);
      expect(find.text('2 người'), findsOneWidget);

      // Default PvE shows levels and colors
      expect(find.text('Dễ'), findsOneWidget);
      expect(find.text('Trung bình'), findsOneWidget);
      expect(find.text('Khó'), findsOneWidget);

      expect(find.text('Trắng'), findsOneWidget);
      expect(find.text('Đen'), findsOneWidget);
      expect(find.text('Ngẫu nhiên'), findsOneWidget);

      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('selecting 2 người hides level and color options', (
      tester,
    ) async {
      await pumpHome(tester);

      // Tap '2 người'
      await tester.tap(find.text('2 người'));
      await tester.pump();

      // Levels and colors should be hidden
      expect(find.text('Dễ'), findsNothing);
      expect(find.text('Trung bình'), findsNothing);
      expect(find.text('Khó'), findsNothing);
      expect(find.text('Trắng'), findsNothing);
      expect(find.text('Đen'), findsNothing);
      expect(find.text('Ngẫu nhiên'), findsNothing);

      // Switch back to 'Chơi với máy'
      await tester.tap(find.text('Chơi với máy'));
      await tester.pump();

      expect(find.text('Dễ'), findsOneWidget);
      expect(find.text('Trắng'), findsOneWidget);
    });

    testWidgets(
      'selecting PvE + Khó + Đen -> Bắt đầu navigates to GamePage with correct GameConfig',
      (tester) async {
        await pumpHome(tester);

        // Select 'Khó'
        await tester.tap(find.text('Khó'));
        await tester.pump();

        // Select 'Đen'
        await tester.tap(find.text('Đen'));
        await tester.pump();

        // Tap 'Bắt đầu'
        await tester.tap(find.text('Bắt đầu'));
        await tester.pumpAndSettle();

        // Should be on GamePage
        expect(find.byType(GamePage), findsOneWidget);
        final gamePage = tester.widget<GamePage>(find.byType(GamePage));
        expect(gamePage.config.mode, GameMode.pve);
        expect(gamePage.config.level, AiLevel.hard);
        expect(gamePage.config.humanColor, PieceColor.black);

        // AppBar title should be 'Máy - Khó'
        expect(find.text('Máy - Khó'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting 2 người -> Bắt đầu navigates to GamePage with GameConfig.pvp()',
      (tester) async {
        await pumpHome(tester);

        await tester.tap(find.text('2 người'));
        await tester.pump();

        await tester.tap(find.text('Bắt đầu'));
        await tester.pumpAndSettle();

        expect(find.byType(GamePage), findsOneWidget);
        final gamePage = tester.widget<GamePage>(find.byType(GamePage));
        expect(gamePage.config.mode, GameMode.pvp);

        // AppBar title should be '2 người'
        expect(find.text('2 người'), findsOneWidget);
      },
    );

    testWidgets('ColorChoice.random resolves color at start time', (
      tester,
    ) async {
      // Test random = true -> PieceColor.white
      await pumpHome(tester, random: _FixedRandom(true));
      await tester.tap(find.text('Ngẫu nhiên'));
      await tester.pump();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      var gamePage = tester.widget<GamePage>(find.byType(GamePage));
      expect(gamePage.config.humanColor, PieceColor.white);

      // Pop back to home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Test random = false -> PieceColor.black
      await pumpHome(tester, random: _FixedRandom(false));
      await tester.tap(find.text('Ngẫu nhiên'));
      await tester.pump();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      gamePage = tester.widget<GamePage>(find.byType(GamePage));
      expect(gamePage.config.humanColor, PieceColor.black);
    });

    testWidgets('tapping back button on GamePage navigates back to HomePage', (
      tester,
    ) async {
      await pumpHome(tester);

      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePage), findsOneWidget);

      // Tap back button
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(GamePage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets(
      'saved game: hidden when no saved game, visible when saved game exists and opens GamePage with restore',
      (tester) async {
        // 1. Khi chưa có ván lưu -> nút Tiếp tục bị ẩn
        when(repo.load).thenReturn(null);
        await pumpHome(tester);
        expect(find.text('Tiếp tục ván đang chơi'), findsNothing);

        // 2. Khi có ván lưu -> nút Tiếp tục hiển thị
        const saved = SavedGame(
          startFen: Fen.initial,
          moves: ['e2e4', 'e7e5'],
          config: GameConfig(
            mode: GameMode.pve,
            humanColor: PieceColor.white,
            level: AiLevel.hard,
          ),
        );
        when(repo.load).thenReturn(saved);

        await pumpHome(tester, key: const Key('has-saved'));
        expect(find.text('Tiếp tục ván đang chơi'), findsOneWidget);

        // 3. Bấm "Tiếp tục ván đang chơi" -> mở GamePage với restore
        await tester.tap(find.text('Tiếp tục ván đang chơi'));
        await tester.pumpAndSettle();

        final gamePage = tester.widget<GamePage>(find.byType(GamePage));
        expect(gamePage.restore, saved);
        expect(gamePage.config, saved.config);

        // 4. Quay về màn chính -> refresh được gọi
        when(repo.load).thenReturn(null); // Giả lập ván đã kết thúc/xóa
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.text('Tiếp tục ván đang chơi'), findsNothing);
      },
    );

    testWidgets(
      'tapping settings button on HomePage navigates to SettingsPage',
      (tester) async {
        await pumpHome(tester);

        final settingsButton = find.byTooltip('Cài đặt');
        expect(settingsButton, findsOneWidget);

        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.text('Cài đặt'), findsOneWidget);
      },
    );
  });
}
