import 'package:flutter/material.dart';

/// Theme cổ điển của app: nâu gỗ / ngà / vàng đồng (tối) và kem / nâu gỗ (sáng).
/// Bảng màu tối chốt trong T4.5; bảng màu sáng lấy theo logo và splash (T4.8),
/// nền sáng trùng màu nền splash để mở app không bị đổi màu đột ngột.
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
    onPrimary: Color(0xFFFAF0DE),
    primaryContainer: Color(0xFFE6CFA8),
    onPrimaryContainer: Color(0xFF2A1E16),
    secondary: Color(0xFF6B523C),
    onSecondary: Color(0xFFFAF0DE),
    tertiary: Color(0xFF855A38),
    onTertiary: Color(0xFFFFF8EC),
    error: Color(0xFFA4483A),
    onError: Color(0xFFFBF6EA),
    errorContainer: Color(0xFFF5D9D3),
    onErrorContainer: Color(0xFF4A2019),
    surface: Color(0xFFF2E1C3),
    onSurface: Color(0xFF2A1E16),
    onSurfaceVariant: Color(0xFF6B523C),
    surfaceContainerLowest: Color(0xFFFFF8EC),
    surfaceContainerLow: Color(0xFFFAF0DE),
    surfaceContainer: Color(0xFFEAD6B4),
    surfaceContainerHigh: Color(0xFFE3CCA6),
    surfaceContainerHighest: Color(0xFFDBC198),
    outline: Color(0xFF9A6B45),
    outlineVariant: Color(0xFFDCC6A0),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF2A1E16),
    onInverseSurface: Color(0xFFF2E1C3),
  );

  /// [animations] theo cài đặt `Hiệu ứng chuyển động`: tắt thì chuyển trang
  /// ngay và nút không co khi nhấn.
  static ThemeData light({bool animations = true}) =>
      _build(lightScheme, animations: animations);

  static ThemeData dark({bool animations = true}) =>
      _build(darkScheme, animations: animations);

  /// Nền thẻ: nền tối cần thẻ sáng hơn hẳn nền vì không có viền hay bóng để
  /// tách; nền sáng thì thẻ sáng hơn nền.
  static Color cardColor(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
      ? scheme.surfaceContainer
      : scheme.surfaceContainerLow;

  static ThemeData _build(ColorScheme scheme, {required bool animations}) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final cardColor = AppTheme.cardColor(scheme);
    final transitions = animations
        ? const _FadePageTransitionsBuilder()
        : const _NoPageTransitionsBuilder();
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
      extensions: [AppMotion(enabled: animations)],
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values) platform: transitions,
        },
      ),
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
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: const WidgetStatePropertyAll(BorderSide.none),
          backgroundColor: _whenSelected(scheme.primary, cardColor),
          foregroundColor: _whenSelected(scheme.onPrimary, scheme.onSurface),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: _whenSelected(scheme.onPrimary, scheme.onSurfaceVariant),
        trackColor: _whenSelected(scheme.primary, scheme.surfaceContainerHigh),
        trackOutlineColor: _whenSelected(scheme.primary, scheme.outlineVariant),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.tertiary,
        inactiveTrackColor: scheme.outlineVariant,
        thumbColor: scheme.tertiary,
      ),
      dialogTheme: DialogThemeData(
        // Không viền: nền tối cần sáng hẳn lên mới tách khỏi lớp phủ phía sau.
        backgroundColor: scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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

/// Cờ bật/tắt hiệu ứng chuyển động cho widget dùng chung (vd. [PressScale]),
/// lấy từ cài đặt khi dựng theme để widget không phải đọc cubit cài đặt.
@immutable
final class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({required this.enabled});

  final bool enabled;

  /// Mặc định bật khi theme không có extension này (vd. test dựng theme riêng).
  static bool enabledOf(BuildContext context) =>
      Theme.of(context).extension<AppMotion>()?.enabled ?? true;

  @override
  AppMotion copyWith({bool? enabled}) =>
      AppMotion(enabled: enabled ?? this.enabled);

  @override
  AppMotion lerp(AppMotion? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Trang mới hiện mờ dần lên trên trang cũ.
final class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

/// Tắt hiệu ứng: trang mới hiện ngay.
final class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
