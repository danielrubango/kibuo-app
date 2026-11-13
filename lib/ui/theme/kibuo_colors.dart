import 'package:flutter/painting.dart';

/// The validated palette of docs/design/DIRECTION.md, light theme only.
///
/// Each tint comes with the ink colour that reads on it, so a widget picks a
/// pair rather than two unrelated colours.
abstract final class KibuoColors {
  // Base.
  static const background = Color(0xFFEEF1F7);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0E1320);
  static const inkSecondary = Color(0xFF525D73);
  static const inkMuted = Color(0xFF8A93A6);
  static const line = Color(0xFFC9CFDB);
  static const lineStrong = Color(0xFFB6BDCB);
  static const track = Color(0xFFDDE2EC);
  static const fill = Color(0xFFE4E8F0);

  // Brand.
  static const mint = Color(0xFF5EEAB5);
  static const coin = Color(0xFFFFC247);

  // Meaning: good, money coming in.
  static const accent = Color(0xFF0A7355);
  static const accentTint = Color(0xFFE9F8F1);
  static const accentTintStrong = Color(0xFFD5F2E4);

  // Meaning: what I owe, money going out.
  static const debtInk = Color(0xFF8A4B12);
  static const debtTint = Color(0xFFFFE6D3);
  static const debtLine = Color(0xFFE8A878);

  // Meaning: projects, money set aside.
  static const projectInk = Color(0xFF33528A);
  static const projectTint = Color(0xFFE1E8F6);
  static const projectLine = Color(0xFF8FA8D6);

  // Meaning: warning (budget at 80 %).
  static const warning = Color(0xFFD99A1C);
  static const warningInk = Color(0xFF8A5A00);
  static const warningTint = Color(0xFFFCEFD2);

  // Meaning: late or over budget.
  static const danger = Color(0xFFB3321A);
}
