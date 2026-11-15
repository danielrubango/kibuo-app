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
  static const caretLeft = IconData(0xe138, fontFamily: _regular);
  static const caretDown = IconData(0xe136, fontFamily: _regular);
  static const arrowLeft = IconData(0xe058, fontFamily: _regular);
  static const check = IconData(0xe182, fontFamily: _regular);
  static const copy = IconData(0xe1ca, fontFamily: _regular);
  static const key = IconData(0xe2d6, fontFamily: _regular);
  static const fingerprint = IconData(0xe23e, fontFamily: _regular);
  static const magnifyingGlass = IconData(0xe30c, fontFamily: _regular);
  static const wallet = IconData(0xe68a, fontFamily: _regular);
  static const bank = IconData(0xe0b4, fontFamily: _regular);
  static const deviceMobile = IconData(0xe1e0, fontFamily: _regular);
  static const piggyBank = IconData(0xea04, fontFamily: _regular);
  static const camera = IconData(0xe10e, fontFamily: _regular);
  static const image = IconData(0xe2ca, fontFamily: _regular);
  static const file = IconData(0xe230, fontFamily: _regular);
  static const filePdf = IconData(0xe702, fontFamily: _regular);
  static const paperclip = IconData(0xe39a, fontFamily: _regular);
  static const checkCircleFill = IconData(0xe184, fontFamily: _fill);
  static const forkKnife = IconData(0xe262, fontFamily: _regular);
  static const basket = IconData(0xe964, fontFamily: _regular);
  static const taxi = IconData(0xe902, fontFamily: _regular);
  static const motorcycle = IconData(0xe80a, fontFamily: _regular);
  static const bus = IconData(0xe106, fontFamily: _regular);
  static const gasPump = IconData(0xe768, fontFamily: _regular);
  static const roadHorizon = IconData(0xe838, fontFamily: _regular);
  static const lightning = IconData(0xe2de, fontFamily: _regular);
  static const drop = IconData(0xe210, fontFamily: _regular);
  static const phone = IconData(0xe3b8, fontFamily: _regular);
  static const wifiHigh = IconData(0xe4ea, fontFamily: _regular);
  static const firstAid = IconData(0xe56e, fontFamily: _regular);
  static const pill = IconData(0xe700, fontFamily: _regular);
  static const usersThree = IconData(0xe68e, fontFamily: _regular);
  static const popcorn = IconData(0xeb4e, fontFamily: _regular);
  static const dotsThreeCircle = IconData(0xe200, fontFamily: _regular);
  static const tag = IconData(0xe478, fontFamily: _regular);
  static const arrowCounterClockwise = IconData(0xe038, fontFamily: _regular);
  static const church = IconData(0xecea, fontFamily: _regular);
  static const baby = IconData(0xe774, fontFamily: _regular);
  static const tShirt = IconData(0xe670, fontFamily: _regular);
  static const heartbeat = IconData(0xe2ac, fontFamily: _regular);
  static const barbell = IconData(0xe0b6, fontFamily: _regular);
  static const wrench = IconData(0xe5d4, fontFamily: _regular);
  static const receipt = IconData(0xe3ec, fontFamily: _regular);
  static const pawPrint = IconData(0xe648, fontFamily: _regular);
  static const bookOpen = IconData(0xe0e6, fontFamily: _regular);
  static const tooth = IconData(0xe9cc, fontFamily: _regular);
  static const money = IconData(0xe588, fontFamily: _regular);
  static const currencyCircleDollar = IconData(0xe54c, fontFamily: _regular);
  static const calendarBlank = IconData(0xe10a, fontFamily: _regular);
  static const slidersHorizontal = IconData(0xe434, fontFamily: _regular);
  static const caretUp = IconData(0xe13c, fontFamily: _regular);
  static const briefcase = IconData(0xe0ee, fontFamily: _regular);
  static const storefront = IconData(0xe470, fontFamily: _regular);
  static const users = IconData(0xe4d6, fontFamily: _regular);
  static const car = IconData(0xe112, fontFamily: _regular);
  static const graduationCap = IconData(0xe62c, fontFamily: _regular);
  static const heart = IconData(0xe2a8, fontFamily: _regular);
  static const gift = IconData(0xe276, fontFamily: _regular);
  static const airplane = IconData(0xe002, fontFamily: _regular);
  static const shoppingCart = IconData(0xe41e, fontFamily: _regular);
  static const coins = IconData(0xe78e, fontFamily: _regular);
  static const creditCard = IconData(0xe1d2, fontFamily: _regular);
  static const globe = IconData(0xe288, fontFamily: _regular);
  static const star = IconData(0xe46a, fontFamily: _regular);
  static const lockSimple = IconData(0xe308, fontFamily: _regular);
  static const handHeart = IconData(0xe810, fontFamily: _regular);
  static const plant = IconData(0xebae, fontFamily: _regular);

  static const lockKey = IconData(0xe2fe, fontFamily: _regular);
  static const x = IconData(0xe4f6, fontFamily: _regular);
  static const xBold = IconData(0xe4f6, fontFamily: _bold);
  static const plusBold = IconData(0xe3d4, fontFamily: _bold);
}
