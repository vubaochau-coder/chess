import 'package:chess/theme/app_theme.dart';
import 'package:chess/theme/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required ThemeData theme,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: PressScale(
            enabled: enabled,
            child: TextButton(onPressed: onTap, child: const Text('Nút')),
          ),
        ),
      ),
    );
  }

  double scaleOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  group('PressScale', () {
    testWidgets('shrinks while pressed and restores on release', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(theme: AppTheme.dark(), onTap: () => taps++),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Nút')),
      );
      await tester.pump();
      expect(scaleOf(tester), PressScale.pressedScale);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scaleOf(tester), 1);
      expect(taps, 1, reason: 'không chặn chạm của nút bên trong');
    });

    testWidgets('does not shrink when animations are off', (tester) async {
      await tester.pumpWidget(host(theme: AppTheme.dark(animations: false)));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Nút')),
      );
      await tester.pump();
      expect(scaleOf(tester), 1);
      await gesture.up();
    });

    testWidgets('does not shrink when disabled', (tester) async {
      await tester.pumpWidget(host(theme: AppTheme.dark(), enabled: false));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Nút')),
      );
      await tester.pump();
      expect(scaleOf(tester), 1);
      await gesture.up();
    });
  });
}
