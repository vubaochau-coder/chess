import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/features/settings/view/settings_page.dart';
import 'package:chess/theme/board_theme.dart';
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
      expect(find.text('Giao diện'), findsOneWidget);
      expect(find.text('Chế độ màu'), findsOneWidget);
      expect(find.text('Theo hệ thống'), findsOneWidget);
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tối'), findsOneWidget);
      expect(find.text('Màu bàn cờ'), findsOneWidget);
      expect(find.text('Gỗ'), findsOneWidget);
      expect(find.text('Xanh lá'), findsOneWidget);
      expect(find.text('Xanh dương'), findsOneWidget);
      expect(find.text('Xám'), findsOneWidget);
      expect(find.text('Tím'), findsOneWidget);
    });

    testWidgets('tapping Tối calls cubit.setThemeMode(AppThemeMode.dark)', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const AppSettings());

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
  });
}
