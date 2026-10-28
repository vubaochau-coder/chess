import 'package:flutter/material.dart';

/// Theme cổ điển của app: nâu gỗ / ngà / vàng đồng (tối) và giấy cũ / nâu đậm
/// (sáng). Bảng màu chốt trong đặc tả T4.5.
abstract final class AppTheme {
  /// Font có chân của hệ thống (Noto Serif trên Android, có dấu tiếng Việt).
  static const String serifFamily = 'serif';

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFC8A15A),
    onPrimary: Color(0xFF1B140F),
    primaryContainer: Color(0xFF3A2D1A),
    onPrimaryContainer: Color(0xFFF2DDAE),
    secondary: Color(0xFFCBB894),
    onSecondary: Color(0xFF1B140F),
    tertiary: Color(0xFFC8A15A),
    onTertiary: Color(0xFF1B140F),
    error: Color(0xFFA4483A),
    onError: Color(0xFFFBF6EA),
    errorContainer: Color(0xFF4A2019),
    onErrorContainer: Color(0xFFF5C9C0),
    surface: Color(0xFF17110D),
    onSurface: Color(0xFFF2E8D5),
    onSurfaceVariant: Color(0xFFB7A58A),
    surfaceContainerLowest: Color(0xFF120D0A),
    surfaceContainerLow: Color(0xFF1E1712),
    surfaceContainer: Color(0xFF221A14),
    surfaceContainerHigh: Color(0xFF2A2018),
    surfaceContainerHighest: Color(0xFF31261C),
    outline: Color(0xFF6E5832),
    outlineVariant: Color(0xFF3A2E24),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFFF2E8D5),
    onInverseSurface: Color(0xFF17110D),
  );

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2A1E16),
    onPrimary: Color(0xFFF6F0E4),
    primaryContainer: Color(0xFFEADBBE),
    onPrimaryContainer: Color(0xFF2A1E16),
    secondary: Color(0xFF6F5E48),
    onSecondary: Color(0xFFF6F0E4),
    tertiary: Color(0xFF8A6A2F),
    onTertiary: Color(0xFFFFFBF3),
    error: Color(0xFFA4483A),
    onError: Color(0xFFFBF6EA),
    errorContainer: Color(0xFFF5D9D3),
    onErrorContainer: Color(0xFF4A2019),
    surface: Color(0xFFF6F0E4),
    onSurface: Color(0xFF2A1E16),
    onSurfaceVariant: Color(0xFF6F5E48),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFBF3),
    surfaceContainer: Color(0xFFF1E9D9),
    surfaceContainerHigh: Color(0xFFEBE1CD),
    surfaceContainerHighest: Color(0xFFE4D8C1),
    outline: Color(0xFFA8833F),
    outlineVariant: Color(0xFFE2D5BE),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF2A1E16),
    onInverseSurface: Color(0xFFF6F0E4),
  );

  static ThemeData light() => _build(lightScheme);

  static ThemeData dark() => _build(darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = base.textTheme.copyWith(
      displayLarge: _serif(base.textTheme.displayLarge),
      displayMedium: _serif(base.textTheme.displayMedium),
      displaySmall: _serif(base.textTheme.displaySmall),
      headlineLarge: _serif(base.textTheme.headlineLarge),
      headlineMedium: _serif(base.textTheme.headlineMedium),
      headlineSmall: _serif(base.textTheme.headlineSmall),
      titleLarge: _serif(base.textTheme.titleLarge),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: serifFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: _whenSelected(
            scheme.primary,
            scheme.surfaceContainerLow,
          ),
          foregroundColor: _whenSelected(scheme.onPrimary, scheme.onSurface),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline),
        ),
        titleTextStyle: TextStyle(
          fontFamily: serifFamily,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static TextStyle? _serif(TextStyle? style) =>
      style?.copyWith(fontFamily: serifFamily, fontWeight: FontWeight.w700);

  static WidgetStateProperty<Color> _whenSelected(Color on, Color off) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? on : off,
      );
}
