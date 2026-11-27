import 'package:flutter/widgets.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// The icons a category can take, by the name that is stored.
const categoryIcons = <String, IconData>{
  'forkKnife': KibuoIcons.forkKnife,
  'basket': KibuoIcons.basket,
  'shoppingCart': KibuoIcons.shoppingCart,
  'car': KibuoIcons.car,
  'taxi': KibuoIcons.taxi,
  'motorcycle': KibuoIcons.motorcycle,
  'bus': KibuoIcons.bus,
  'gasPump': KibuoIcons.gasPump,
  'roadHorizon': KibuoIcons.roadHorizon,
  'airplane': KibuoIcons.airplane,
  'house': KibuoIcons.house,
  'lightning': KibuoIcons.lightning,
  'drop': KibuoIcons.drop,
  'phone': KibuoIcons.phone,
  'wifiHigh': KibuoIcons.wifiHigh,
  'wrench': KibuoIcons.wrench,
  'firstAid': KibuoIcons.firstAid,
  'pill': KibuoIcons.pill,
  'heartbeat': KibuoIcons.heartbeat,
  'graduationCap': KibuoIcons.graduationCap,
  'usersThree': KibuoIcons.usersThree,
  'baby': KibuoIcons.baby,
  'tShirt': KibuoIcons.tShirt,
  'popcorn': KibuoIcons.popcorn,
  'barbell': KibuoIcons.barbell,
  'church': KibuoIcons.church,
  'handCoins': KibuoIcons.handCoins,
  'gift': KibuoIcons.gift,
  'money': KibuoIcons.money,
  'coins': KibuoIcons.coins,
  'piggyBank': KibuoIcons.piggyBank,
  'storefront': KibuoIcons.storefront,
  'briefcase': KibuoIcons.briefcase,
  'tag': KibuoIcons.tag,
  'arrowCounterClockwise': KibuoIcons.arrowCounterClockwise,
  'dotsThreeCircle': KibuoIcons.dotsThreeCircle,
  'arrowsDownUp': KibuoIcons.arrowsDownUp,
};

/// A category's name: the user's, else the app's language for a provided
/// one.
String categoryName(AppLocalizations l, CategoryInfo c) =>
    c.name ?? l.categoryName(c.key ?? '');

IconData categoryIcon(CategoryInfo c) =>
    categoryIcons[c.icon] ?? KibuoIcons.tag;

/// Expenses in peach, income in green (DIRECTION: amounts and tiles follow
/// their meaning).
({Color tint, Color ink}) categoryColors(CategoryKind kind) =>
    kind == CategoryKind.out
    ? (tint: KibuoColors.debtTint, ink: KibuoColors.debtInk)
    : (tint: KibuoColors.accentTint, ink: KibuoColors.accent);

/// The hue of a category's colour, on its tile and its bar (SYSTEM
/// « Couleurs des catégories », ADR 0014).
Color categoryHue(CategoryColor c) => switch (c) {
  CategoryColor.peach => const Color(0xFFE8A878),
  CategoryColor.apricot => const Color(0xFFF2C48D),
  CategoryColor.sand => const Color(0xFFDCC79A),
  CategoryColor.coral => const Color(0xFFEE9F92),
  CategoryColor.rose => const Color(0xFFD9A0C4),
  CategoryColor.lavender => const Color(0xFFB9A8E2),
  CategoryColor.blue => const Color(0xFF9DB4E0),
  CategoryColor.sky => const Color(0xFF8ED0E6),
  CategoryColor.mint => const Color(0xFF5EEAB5),
  CategoryColor.green => const Color(0xFF7FCBA8),
  CategoryColor.grey => const Color(0xFFC9CFDB),
};

/// The tinted tile of a category's icon.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    this.size = 28,
    this.muted = false,
    this.colored = false,
  });

  final CategoryInfo category;
  final double size;

  /// Grey: an operation ignored or still to come.
  final bool muted;

  /// In the category's own colour, the icon in ink (the Aperçu and Plus ›
  /// Catégories, PRODUCT); else peach or green by its kind.
  final bool colored;

  @override
  Widget build(BuildContext context) {
    // A debt's operations take its colour, whichever way the money goes
    // (canvas OpDetteA4).
    final colors = colored
        ? (tint: categoryHue(category.color), ink: KibuoColors.ink)
        : switch (debtOweOf(category.key)) {
            true => categoryColors(CategoryKind.out),
            false => categoryColors(CategoryKind.into),
            null => categoryColors(category.kind),
          };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: muted ? KibuoColors.background : colors.tint,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        categoryIcon(category),
        size: size * 0.6,
        color: muted ? KibuoColors.inkMuted : colors.ink,
      ),
    );
  }
}
