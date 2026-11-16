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

  /// Under the subcategories of an opened category.
  static const fillSoft = Color(0xFFF4F6FA);

  // Brand.
  static const mint = Color(0xFF5EEAB5);
  static const coin = Color(0xFFFFC247);

  // Meaning: good, money coming in.
  static const accent = Color(0xFF0A7355);
  static const accentTint = Color(0xFFE9F8F1);
  static const accentTintStrong = Color(0xFFD5F2E4);

  /// A dark green for text on the mint « Dépense » choice.
  static const accentDeep = Color(0xFF1F3A30);

  /// An opened category's toggle.
  static const accentTintOpen = Color(0xFFCDEFE0);

  // Meaning: what I owe, money going out.
  static const debtInk = Color(0xFF8A4B12);
  static const debtTint = Color(0xFFFFE6D3);
  static const debtLine = Color(0xFFE8A878);

  /// The edge of an expense's amount card.
  static const debtEdge = Color(0xFFF2CFB3);

  // Meaning: projects, money set aside.
  static const projectInk = Color(0xFF33528A);
  static const projectTint = Color(0xFFE1E8F6);
  static const projectLine = Color(0xFF8FA8D6);

  /// A transfer's amount card and its edge (canvas TransfertMeme).
  static const transferTint = Color(0xFFEEF2FA);
  static const transferEdge = Color(0xFFC6D3EC);

  // Meaning: warning (budget at 80 %).
  static const warning = Color(0xFFD99A1C);
  static const warningInk = Color(0xFF8A5A00);
  static const warningTint = Color(0xFFFCEFD2);

  // Meaning: late or over budget.
  static const danger = Color(0xFFB3321A);

  /// What fills a danger button held down.
  static const dangerTint = Color(0xFFFBE3DE);

  // The veil behind a sheet: ink at 42 %, the page below stays readable.
  static const scrim = Color(0x6B0E1320);

  /// The light veil behind a menu or the month picker: ink at 12 %.
  static const veil = Color(0x1F0E1320);

  /// Behind a first-visit tip: ink at 45 %, with a light blur.
  static const tipScrim = Color(0x730E1320);

  /// The shadow of a bar floating over the content (keypad, selection).
  static const barShadow = Color(0x2E0E1320);

  /// The shadow of the + fan's choices.
  static const fanShadow = Color(0x40000000);
}
