import 'package:bloc_test/bloc_test.dart';
import 'package:chess/core/settings/app_settings.dart';
import 'package:chess/core/storage/settings_repository.dart';
import 'package:chess/features/settings/cubit/settings_cubit.dart';
import 'package:chess/theme/board_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  late SettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  group('SettingsCubit', () {
    test('initial state is loaded from repository', () {
      when(repository.load)
          .thenReturn(const AppSettings(themeMode: AppThemeMode.dark));

      final cubit = SettingsCubit(repository: repository);
      expect(cubit.state, const AppSettings(themeMode: AppThemeMode.dark));
      verify(repository.load).called(1);
    });

    blocTest<SettingsCubit, AppSettings>(
      'setThemeMode emits updated state and calls repository.save',
      setUp: () {
        when(repository.load).thenReturn(const AppSettings());
        when(() => repository.save(any())).thenAnswer((_) async {});
      },
      build: () => SettingsCubit(repository: repository),
      act: (cubit) => cubit.setThemeMode(AppThemeMode.dark),
      expect: () => [const AppSettings(themeMode: AppThemeMode.dark)],
      verify: (_) {
        verify(
          () =>
              repository.save(const AppSettings(themeMode: AppThemeMode.dark)),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'setThemeMode does nothing when setting same themeMode',
      setUp: () {
        when(repository.load)
            .thenReturn(const AppSettings(themeMode: AppThemeMode.dark));
      },
      build: () => SettingsCubit(repository: repository),
      act: (cubit) => cubit.setThemeMode(AppThemeMode.dark),
      expect: () => <AppSettings>[],
      verify: (_) {
        verifyNever(() => repository.save(any()));
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'setBoardTheme emits updated state and calls repository.save',
      setUp: () {
        when(repository.load).thenReturn(const AppSettings());
        when(() => repository.save(any())).thenAnswer((_) async {});
      },
      build: () => SettingsCubit(repository: repository),
      act: (cubit) => cubit.setBoardTheme(BoardTheme.green),
      expect: () => [const AppSettings(boardTheme: BoardTheme.green)],
      verify: (_) {
        verify(
          () =>
              repository.save(const AppSettings(boardTheme: BoardTheme.green)),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'setBoardTheme does nothing when setting same boardTheme',
      setUp: () {
        when(repository.load)
            .thenReturn(const AppSettings(boardTheme: BoardTheme.green));
      },
      build: () => SettingsCubit(repository: repository),
      act: (cubit) => cubit.setBoardTheme(BoardTheme.green),
      expect: () => <AppSettings>[],
      verify: (_) {
        verifyNever(() => repository.save(any()));
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'setShowCoordinates emits updated state and saves it',
      setUp: () {
        when(repository.load).thenReturn(const AppSettings());
        when(() => repository.save(any())).thenAnswer((_) async {});
      },
      build: () => SettingsCubit(repository: repository),
      act: (cubit) => cubit.setShowCoordinates(false),
      expect: () => [const AppSettings(showCoordinates: false)],
      verify: (_) {
        verify(() => repository.save(const AppSettings(showCoordinates: false)))
            .called(1);
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'setSoundVolume clamps the value into 0..1',
      setUp: () {
        when(repository.load).thenReturn(const AppSettings());
        when(() => repository.save(any())).thenAnswer((_) async {});
      },
      build: () => SettingsCubit(repository: repository),
      act: (cubit) => cubit.setSoundVolume(1.5),
      expect: () => [const AppSettings(soundVolume: 1)],
    );
  });
}
