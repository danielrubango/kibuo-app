import 'package:flutter/widgets.dart';

/// Phosphor icons, bundled from the official font files (MIT licence, see
/// assets/icons/LICENSE-Phosphor.txt). The weights share code points:
/// regular by default, bold for the + button and the fan's cross. The bottom
/// bar uses icons drawn for Kibuo (see lib/ui/shell/tab_icons.dart).
///
/// To add an icon, look up its code point in the `style.css` of
/// `@phosphor-icons/web` 2.1.2 and add a constant here.
abstract final class KibuoIcons {
  static const _regular = 'PhosphorRegular';
  static const _bold = 'PhosphorBold';
  static const _fill = 'PhosphorFill';

  static const house = IconData(0xe2c2, fontFamily: _regular);
  static const list = IconData(0xe2f0, fontFamily: _regular);
  static const chartBar = IconData(0xe150, fontFamily: _regular);
  static const squaresFour = IconData(0xe464, fontFamily: _regular);

  // Filled versions, for the active tab of the bottom bar.
  static const houseFill = IconData(0xe2c2, fontFamily: _fill);
  static const listFill = IconData(0xe2f0, fontFamily: _fill);
  static const chartBarFill = IconData(0xe150, fontFamily: _fill);
  static const squaresFourFill = IconData(0xe464, fontFamily: _fill);

  static const arrowDown = IconData(0xe03e, fontFamily: _regular);
  static const arrowUp = IconData(0xe08e, fontFamily: _regular);
  static const arrowsLeftRight = IconData(0xe0a0, fontFamily: _regular);
  static const handCoins = IconData(0xea8c, fontFamily: _regular);
  static const target = IconData(0xe47c, fontFamily: _regular);

  static const caretRight = IconData(0xe13a, fontFamily: _regular);
  static const x = IconData(0xe4f6, fontFamily: _regular);
  static const xBold = IconData(0xe4f6, fontFamily: _bold);
  static const plusBold = IconData(0xe3d4, fontFamily: _bold);
}
