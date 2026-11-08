import 'package:flutter/material.dart';

/// Opacity helper that works on every Flutter version without deprecation noise.
extension ColorAlpha on Color {
  Color o(double opacity) => withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}

/// Design tokens for Momentum, exposed through [ThemeExtension] so every
/// widget reads colours from one place and light/dark stay in sync.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentAlt,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentAlt;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;

  LinearGradient get accentGradient => LinearGradient(
        colors: [accent, accentAlt],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const light = AppPalette(
    background: Color(0xFFF5F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF0F8),
    border: Color(0xFFE3E6F0),
    text: Color(0xFF12142A),
    textMuted: Color(0xFF6E7391),
    accent: Color(0xFF6C5CE7),
    accentAlt: Color(0xFFB16CFF),
    success: Color(0xFF1FB57A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4565),
    shadow: Color(0x1A2B2F5C),
  );

  static const dark = AppPalette(
    background: Color(0xFF0A0B14),
    surface: Color(0xFF141625),
    surfaceAlt: Color(0xFF1C1F33),
    border: Color(0xFF262A42),
    text: Color(0xFFF2F3FA),
    textMuted: Color(0xFF8C91AD),
    accent: Color(0xFF8B7CFF),
    accentAlt: Color(0xFFC77DFF),
    success: Color(0xFF2ED69A),
    warning: Color(0xFFFFB547),
    danger: Color(0xFFFF5C7A),
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith({Color? accent}) => AppPalette(
        background: background,
        surface: surface,
        surfaceAlt: surfaceAlt,
        border: border,
        text: text,
        textMuted: textMuted,
        accent: accent ?? this.accent,
        accentAlt: accentAlt,
        success: success,
        warning: warning,
        danger: danger,
        shadow: shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentAlt: l(accentAlt, other.accentAlt),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class AppTheme {
  static const radius = 22.0;
  static const radiusSm = 14.0;

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness b) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: b,
      primary: p.accent,
      secondary: p.accentAlt,
      surface: p.surface,
      error: p.danger,
    );

    final base = ThemeData(useMaterial3: true, brightness: b, colorScheme: scheme);
    final textTheme = base.textTheme.apply(bodyColor: p.text, displayColor: p.text).copyWith(
          displaySmall: base.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800, letterSpacing: -1.2, color: p.text),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800, letterSpacing: -0.8, color: p.text),
          titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700, letterSpacing: -0.4, color: p.text),
          titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600, letterSpacing: -0.2, color: p.text),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(color: p.text, height: 1.35),
          bodySmall: base.textTheme.bodySmall?.copyWith(color: p.textMuted),
          labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        );

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.text,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        hintStyle: TextStyle(color: p.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: p.accent, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        backgroundColor: b == Brightness.dark ? p.surfaceAlt : p.text,
        contentTextStyle: TextStyle(
            color: b == Brightness.dark ? p.text : p.surface, fontWeight: FontWeight.w600),
        actionTextColor: p.accentAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : p.textMuted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceAlt),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerColor: p.border,
    );
  }
}
