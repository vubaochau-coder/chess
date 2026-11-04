import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/features/game/widgets/piece_view.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/features/settings/view/settings_page.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:chess/theme/piece_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsCubit extends MockCubit<AppSettings>
    implements SettingsCubit {}

void main() {
  late SettingsCubit cubit;

  setUp(() {
    cubit = MockSettingsCubit();
  });

  Widget buildSubject() {
    return BlocProvider<SettingsCubit>.value(
      value: cubit,
      child: const MaterialApp(home: SettingsPage()),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders title and theme mode segments', (tester) async {
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());

      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('GIAO DIỆN'), findsOneWidget);
      expect(find.text('Chế độ màu'), findsOneWidget);
      expect(find.text('Theo hệ thống'), findsNothing);
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tối'), findsOneWidget);
      expect(find.text('Màu bàn cờ'), findsOneWidget);
      // Theme bàn cờ và bộ quân cùng có tên "Gỗ".
      expect(find.text('Gỗ'), findsNWidgets(2));
      expect(find.text('Xanh lá'), findsOneWidget);
      expect(find.text('Xanh dương'), findsOneWidget);
      expect(find.text('Xám'), findsOneWidget);
      expect(find.text('Tím'), findsOneWidget);
    });

    testWidgets('tapping Tối calls cubit.setThemeMode(AppThemeMode.dark)', (
      tester,
    ) async {
      when(() => cubit.state)
          .thenReturn(const AppSettings(themeMode: AppThemeMode.light));

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Tối'));
      await tester.pump();

      verify(() => cubit.setThemeMode(AppThemeMode.dark)).called(1);
    });

    testWidgets('tapping Sáng calls cubit.setThemeMode(AppThemeMode.light)', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Sáng'));
      await tester.pump();

      verify(() => cubit.setThemeMode(AppThemeMode.light)).called(1);
    });

    testWidgets('tapping Xanh lá calls cubit.setBoardTheme(BoardTheme.green)', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Xanh lá'));
      await tester.pump();

      verify(() => cubit.setBoardTheme(BoardTheme.green)).called(1);
    });

    testWidgets('lists every piece set with a preview', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());

      expect(find.text('Bộ quân cờ'), findsOneWidget);
      for (final set in PieceSet.values) {
        expect(find.text(set.label), findsAtLeastNWidgets(1));
        final previews = find.byWidgetPredicate(
          (w) => w is PieceView && w.pieceSet == set,
        );
        expect(tester.widgetList<PieceView>(previews).map((p) => p.piece), [
          'K',
          'n',
        ]);
      }
    });

    testWidgets('piece previews use the selected board colors', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => cubit.state)
          .thenReturn(const AppSettings(boardTheme: BoardTheme.purple));

      await tester.pumpWidget(buildSubject());

      final colors = BoardTheme.purple.colors;
      Color squareBehind(String piece) {
        final view = find.byWidgetPredicate(
          (w) =>
              w is PieceView && w.pieceSet == PieceSet.flat && w.piece == piece,
        );
        return tester
            .widget<ColoredBox>(
              find.ancestor(of: view, matching: find.byType(ColoredBox)).first,
            )
            .color;
      }

      expect(squareBehind('K'), colors.lightSquare);
      expect(squareBehind('n'), colors.darkSquare);
    });

    testWidgets('tapping Phẳng calls cubit.setPieceSet(PieceSet.flat)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Phẳng'));
      await tester.pump();

      verify(() => cubit.setPieceSet(PieceSet.flat)).called(1);
    });

    testWidgets('shows the board and sound sections', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());

      expect(find.text('BÀN CỜ'), findsOneWidget);
      expect(find.text('Hiện tọa độ'), findsOneWidget);
      expect(find.text('Hiện nước đi hợp lệ'), findsOneWidget);
      expect(find.text('Tô nước vừa đi'), findsOneWidget);
      expect(find.text('Tự lật bàn khi chơi 2 người'), findsOneWidget);
      expect(find.text('ÂM THANH'), findsOneWidget);
      expect(find.text('Âm lượng'), findsOneWidget);
      expect(find.text('Rung'), findsOneWidget);
    });

    testWidgets('switches call the matching cubit setters', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Hiện tọa độ'));
      await tester.tap(find.text('Tự lật bàn khi chơi 2 người'));
      await tester.tap(find.text('Rung'));
      await tester.pump();

      verify(() => cubit.setShowCoordinates(false)).called(1);
      verify(() => cubit.setAutoFlipInPvp(true)).called(1);
      verify(() => cubit.setHapticsEnabled(false)).called(1);
    });

    testWidgets('switches are drawn at 80% size and toggle when tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());

      final rung = find.ancestor(
        of: find.text('Rung'),
        matching: find.byType(ListTile),
      );
      final toggle = find.descendant(of: rung, matching: find.byType(Switch));
      final scale = tester.widget<Transform>(
        find.ancestor(
          of: toggle,
          matching: find.byWidgetPredicate(
            (w) => w is Transform && w.child is Switch,
          ),
        ),
      );
      expect(scale.transform.entry(0, 0), closeTo(0.8, 1e-9));

      await tester.tap(toggle);
      await tester.pump();

      verify(() => cubit.setHapticsEnabled(false)).called(1);
    });

    testWidgets('motion switch calls setAnimationsEnabled', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => cubit.state).thenReturn(const AppSettings());

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Hiệu ứng chuyển động'));
      await tester.pump();

      verify(() => cubit.setAnimationsEnabled(false)).called(1);
    });

    testWidgets('volume slider is disabled when sound is off', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const muted = AppSettings(soundEnabled: false);
      when(() => cubit.state).thenReturn(muted);

      await tester.pumpWidget(buildSubject());

      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    });
  });
}
