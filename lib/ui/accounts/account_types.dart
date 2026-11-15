import 'package:flutter/widgets.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// The icons a type of one's own can take, by the name that is stored.
const customTypeIcons = <String, IconData>{
  'wallet': KibuoIcons.wallet,
  'bank': KibuoIcons.bank,
  'deviceMobile': KibuoIcons.deviceMobile,
  'currencyCircleDollar': KibuoIcons.currencyCircleDollar,
  'creditCard': KibuoIcons.creditCard,
  'house': KibuoIcons.house,
  'briefcase': KibuoIcons.briefcase,
  'storefront': KibuoIcons.storefront,
  'users': KibuoIcons.users,
  'lockSimple': KibuoIcons.lockSimple,
  'star': KibuoIcons.star,
  'globe': KibuoIcons.globe,
  'piggyBank': KibuoIcons.piggyBank,
  'coins': KibuoIcons.coins,
  'money': KibuoIcons.money,
  'car': KibuoIcons.car,
  'graduationCap': KibuoIcons.graduationCap,
  'heart': KibuoIcons.heart,
  'gift': KibuoIcons.gift,
  'airplane': KibuoIcons.airplane,
  'shoppingCart': KibuoIcons.shoppingCart,
  'handHeart': KibuoIcons.handHeart,
  'plant': KibuoIcons.plant,
};

/// Names and icons of account types, the provided ones and the user's.
class AccountTypeLabels {
  const AccountTypeLabels(this.l, this.custom);

  final AppLocalizations l;
  final List<CustomAccountType> custom;

  CustomAccountType? _own(AccountType t) =>
      custom.where((c) => c.id == t.key).firstOrNull;

  String name(AccountType t) => switch (t) {
    AccountType.cash => l.accountTypeCash,
    AccountType.bank => l.accountTypeBank,
    AccountType.mobile => l.accountTypeMobile,
    AccountType.savings => l.accountTypeSavings,
    _ => _own(t)?.name ?? '',
  };

  IconData icon(AccountType t) => switch (t) {
    AccountType.cash => KibuoIcons.money,
    AccountType.bank => KibuoIcons.bank,
    AccountType.mobile => KibuoIcons.deviceMobile,
    AccountType.savings => KibuoIcons.currencyCircleDollar,
    _ => customTypeIcons[_own(t)?.icon] ?? KibuoIcons.wallet,
  };

  /// The provided types, then the user's.
  List<AccountType> get all => [
    ...AccountType.provided,
    for (final c in custom) c.type,
  ];
}
