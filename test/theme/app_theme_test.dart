import 'package:chess/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('dark theme uses the classic dark palette', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFC8A15A));
      expect(theme.colorScheme.surface, const Color(0xFF17110D));
      expect(theme.colorScheme.tertiary, const Color(0xFFC8A15A));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF17110D));
    });

    test('light theme matches the logo and splash palette', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF2A1E16));
      expect(theme.colorScheme.surface, const Color(0xFFF2E1C3));
      expect(theme.colorScheme.tertiary, const Color(0xFF855A38));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF2E1C3));
    });

    test('headlines and app bar titles use the serif family', () {
      final theme = AppTheme.dark();

      expect(theme.textTheme.displaySmall?.fontFamily, AppTheme.serifFamily);
      expect(
        theme.appBarTheme.titleTextStyle?.fontFamily,
        AppTheme.serifFamily,
      );
    });

    test('cards and dialogs are borderless with soft corners', () {
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        final card = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(card.side, BorderSide.none);
        expect(card.borderRadius, BorderRadius.circular(24));
        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.color, AppTheme.cardColor(theme.colorScheme));

        final dialog = theme.dialogTheme.shape! as RoundedRectangleBorder;
        expect(dialog.side, BorderSide.none);
        expect(dialog.borderRadius, BorderRadius.circular(28));
      }
    });

    test('dark cards stand out from the background without borders', () {
      const scheme = AppTheme.darkScheme;
      expect(AppTheme.cardColor(scheme), scheme.surfaceContainer);
      expect(AppTheme.cardColor(AppTheme.lightScheme), const Color(0xFFFAF0DE));
    });

    test('buttons are pill shaped', () {
      final theme = AppTheme.dark();
      final filled = theme.filledButtonTheme.style!.shape!.resolve({});
      final outlined = theme.outlinedButtonTheme.style!.shape!.resolve({});
      final segmented = theme.segmentedButtonTheme.style!.shape!.resolve({});
      expect(filled, isA<StadiumBorder>());
      expect(outlined, isA<StadiumBorder>());
      expect(segmented, isA<StadiumBorder>());
      expect(
        theme.segmentedButtonTheme.style!.side!.resolve({}),
        BorderSide.none,
      );
    });

    test('motion flag follows the animations setting', () {
      expect(AppTheme.dark().extension<AppMotion>()!.enabled, isTrue);
      expect(
        AppTheme.light(animations: false).extension<AppMotion>()!.enabled,
        isFalse,
      );
    });

    testWidgets('pages fade in when animations are on', (tester) async {
      await tester.pumpWidget(_App(theme: AppTheme.dark()));
      await tester.tap(find.text('Mở'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Trang mới'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(find.text('Trang mới'), findsOneWidget);
    });

    testWidgets('pages open instantly when animations are off', (tester) async {
      await tester.pumpWidget(_App(theme: AppTheme.dark(animations: false)));
      await tester.tap(find.text('Mở'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Trang mới'), findsOneWidget);
      expect(find.text('Mở'), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}

class _App extends StatelessWidget {
  const _App({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Trang mới')),
              ),
            ),
            child: const Text('Mở'),
          ),
        ),
      ),
    );
  }
}
