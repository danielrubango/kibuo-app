import 'package:flutter/material.dart';

import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// Builds the app theme from the validated design direction.
abstract final class KibuoTheme {
  static const displayFont = 'SpaceGrotesk';
  static const textFont = 'Inter';

  /// Corner radii used across the mockups.
  static const radiusCard = 18.0;
  static const radiusTile = 14.0;
  static const radiusSheet = 24.0;

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: KibuoColors.mint,
      onPrimary: KibuoColors.ink,
      secondary: KibuoColors.accent,
      onSecondary: KibuoColors.surface,
      tertiary: KibuoColors.projectInk,
      onTertiary: KibuoColors.surface,
      error: KibuoColors.danger,
      onError: KibuoColors.surface,
      surface: KibuoColors.surface,
      onSurface: KibuoColors.ink,
      onSurfaceVariant: KibuoColors.inkSecondary,
      outline: KibuoColors.line,
      outlineVariant: KibuoColors.track,
      surfaceContainerHighest: KibuoColors.fill,
    );

    final text = textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KibuoColors.background,
      canvasColor: KibuoColors.background,
      fontFamily: textFont,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: KibuoColors.background,
        foregroundColor: KibuoColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: const CardThemeData(
        color: KibuoColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KibuoColors.mint,
          foregroundColor: KibuoColors.ink,
          disabledBackgroundColor: KibuoColors.fill,
          disabledForegroundColor: KibuoColors.inkMuted,
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusTile)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KibuoColors.accent,
          textStyle: text.labelLarge,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KibuoColors.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: KibuoColors.lineStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(KibuoColors.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? KibuoColors.accent
              : KibuoColors.lineStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KibuoColors.accent,
        linearTrackColor: KibuoColors.track,
      ),
      dividerTheme: const DividerThemeData(
        color: KibuoColors.track,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Space Grotesk for titles and amounts, Inter for everything else.
  static TextTheme textTheme() {
    return TextTheme(
      // Big amounts (available money, budget left).
      displayLarge: _display(34, height: 42 / 34),
      displayMedium: _display(30),
      // Screen titles.
      headlineLarge: _display(24),
      headlineMedium: _display(22),
      headlineSmall: _display(20),
      // Card titles and amounts in lists.
      titleLarge: _display(17),
      titleMedium: _text(16, FontWeight.w600),
      titleSmall: _text(15, FontWeight.w600),
      // Running text.
      bodyLarge: _text(15, FontWeight.w500),
      bodyMedium: _text(13, FontWeight.w400, color: KibuoColors.inkSecondary),
      bodySmall: _text(12, FontWeight.w400, color: KibuoColors.inkSecondary),
      // Buttons, chips, small labels.
      labelLarge: _text(15, FontWeight.w600),
      labelMedium: _text(12, FontWeight.w600),
      labelSmall: _text(
        11,
        FontWeight.w600,
        color: KibuoColors.inkSecondary,
        letterSpacing: 0.4,
      ),
    );
  }

  static TextStyle _display(double size, {double? height}) => _style(
    displayFont,
    size,
    FontWeight.w700,
    KibuoColors.ink,
    height: height,
  );

  static TextStyle _text(
    double size,
    FontWeight weight, {
    Color color = KibuoColors.ink,
    double? letterSpacing,
  }) => _style(textFont, size, weight, color, letterSpacing: letterSpacing);

  // Both fonts are variable: the weight axis must be set explicitly.
  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
