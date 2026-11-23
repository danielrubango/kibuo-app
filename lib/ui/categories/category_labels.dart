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

/// The tinted tile of a category's icon.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    this.size = 28,
    this.muted = false,
  });

  final CategoryInfo category;
  final double size;

  /// Grey: an operation ignored or still to come.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    // A debt's operations take its colour, whichever way the money goes
    // (canvas OpDetteA4).
    final colors = switch (debtOweOf(category.key)) {
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
