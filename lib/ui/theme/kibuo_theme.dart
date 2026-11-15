import 'package:flutter/material.dart';

import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// Builds the app theme from the design system (canvas page « Système de
/// design »).
abstract final class KibuoTheme {
  /// Titles, amounts and keypad digits.
  static const displayFont = 'PlusJakartaSans';

  /// Everything else.
  static const textFont = 'Inter';

  /// Only the name « Kibuo » next to the logo.
  static const brandFont = 'SpaceGrotesk';

  // Corner radii, each with its role.
  static const radiusPill = 12.0;
  static const radiusTile = 14.0;
  static const radiusField = 16.0;
  static const radiusCard = 18.0;
  static const radiusFeatured = 22.0;
  static const radiusSheet = 26.0;

  // Heights.
  static const heightTouch = 44.0;
  static const heightSecondary = 48.0;
  static const heightKey = 50.0;
  static const heightField = 52.0;
  static const heightPrimary = 54.0;

  /// Side margins of every screen.
  static const screenMargin = 16.0;

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

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KibuoColors.background,
      canvasColor: KibuoColors.background,
      fontFamily: textFont,
      textTheme: textTheme(),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: KibuoColors.background,
        foregroundColor: KibuoColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 4,
        titleTextStyle: KibuoType.screenTitle,
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(KibuoIcons.caretLeft),
        closeButtonIconBuilder: (_) => const Icon(KibuoIcons.x),
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
          minimumSize: const Size.fromHeight(heightPrimary),
          textStyle: KibuoType.button,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KibuoColors.accent,
          textStyle: KibuoType.buttonSmall,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KibuoColors.background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: KibuoColors.scrim,
        showDragHandle: true,
        dragHandleColor: KibuoColors.line,
        dragHandleSize: Size(40, 4),
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
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: KibuoColors.accent,
        selectionColor: KibuoColors.accentTintStrong,
        selectionHandleColor: KibuoColors.accent,
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

  /// Material's text roles, mapped onto the design system's.
  static TextTheme textTheme() {
    return TextTheme(
      displayLarge: KibuoType.bigAmount,
      displayMedium: KibuoType.highlight,
      displaySmall: KibuoType.enteredValue,
      headlineLarge: KibuoType.tabTitle,
      headlineMedium: KibuoType.screenTitle,
      headlineSmall: KibuoType.sheetTitle,
      titleLarge: KibuoType.cardTitle,
      titleMedium: KibuoType.itemName,
      titleSmall: KibuoType.rowLabel,
      bodyLarge: KibuoType.rowLabel,
      bodyMedium: KibuoType.body,
      bodySmall: KibuoType.caption,
      labelLarge: KibuoType.buttonSmall,
      labelMedium: KibuoType.sectionTitle,
      labelSmall: KibuoType.caption,
    );
  }
}

/// One text style per role of the design system, and no other.
abstract final class KibuoType {
  static final tabTitle = _display(24);
  static final screenTitle = _display(22);
  static final sheetTitle = _display(20);
  static final bigAmount = _display(34);
  static final highlight = _display(28);
  static final enteredValue = _display(26);
  static final cardTitle = _display(17);
  static final key = _display(22, weight: 500);

  static final itemName = _text(16, 600);
  static final rowLabel = _text(15, 500);
  static final body = _text(14, 400);
  static final sectionTitle = _text(13, 600, color: KibuoColors.inkSecondary);
  static final help = _text(
    13,
    400,
    color: KibuoColors.inkSecondary,
    height: 18 / 13,
  );
  static final caption = _text(12, 400, color: KibuoColors.inkSecondary);
  static final button = _text(16, 600);
  static final buttonSmall = _text(15, 600);

  // Both fonts are variable: the weight axis is set explicitly.
  static TextStyle _display(double size, {int weight = 700}) => TextStyle(
    fontFamily: KibuoTheme.displayFont,
    fontSize: size,
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [FontVariation.weight(weight.toDouble())],
    color: KibuoColors.ink,
  );

  // Inter also gets its optical size, as browsers give it, so its spacing
  // matches the mock-ups.
  static TextStyle _text(
    double size,
    int weight, {
    Color color = KibuoColors.ink,
    double? height,
  }) => TextStyle(
    fontFamily: KibuoTheme.textFont,
    fontSize: size,
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [
      FontVariation.weight(weight.toDouble()),
      FontVariation('opsz', size.clamp(14, 32).toDouble()),
    ],
    color: color,
    height: height,
  );
}
