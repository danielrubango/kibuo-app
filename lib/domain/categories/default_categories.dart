/// The categories Kibuo starts with (validated 15 November 2026). Their
/// names come from the app's language by [key] until the user renames them.
library;

/// Expense or income.
enum CategoryKind {
  out,
  into;

  String get stored => this == out ? 'out' : 'in';

  static CategoryKind fromStored(String s) => s == 'in' ? into : out;
}

class DefaultCategory {
  const DefaultCategory(this.key, this.icon, [this.subs = const []]);

  final String key;

  /// The Phosphor icon's name.
  final String icon;
  final List<DefaultCategory> subs;
}

const defaultExpenses = [
  DefaultCategory('food', 'forkKnife', [
    DefaultCategory('restaurant', 'forkKnife'),
    DefaultCategory('market', 'basket'),
  ]),
  DefaultCategory('transport', 'car', [
    DefaultCategory('taxi', 'taxi'),
    DefaultCategory('motoTaxi', 'motorcycle'),
    DefaultCategory('bus', 'bus'),
    DefaultCategory('fuel', 'gasPump'),
    DefaultCategory('toll', 'roadHorizon'),
  ]),
  DefaultCategory('groceries', 'shoppingCart'),
  DefaultCategory('housing', 'house', [
    DefaultCategory('rent', 'house'),
    DefaultCategory('electricity', 'lightning'),
    DefaultCategory('water', 'drop'),
  ]),
  DefaultCategory('communication', 'phone', [
    DefaultCategory('airtime', 'phone'),
    DefaultCategory('internet', 'wifiHigh'),
  ]),
  DefaultCategory('health', 'firstAid', [DefaultCategory('pharmacy', 'pill')]),
  DefaultCategory('school', 'graduationCap'),
  DefaultCategory('family', 'usersThree'),
  DefaultCategory('outings', 'popcorn'),
  DefaultCategory('contributions', 'handCoins'),
  DefaultCategory('otherExpense', 'dotsThreeCircle'),
];

const defaultIncome = [
  DefaultCategory('salary', 'money'),
  DefaultCategory('business', 'storefront', [
    DefaultCategory('sale', 'tag'),
    DefaultCategory('service', 'briefcase'),
  ]),
  DefaultCategory('giftReceived', 'gift'),
  DefaultCategory('refund', 'arrowCounterClockwise'),
  DefaultCategory('otherIncome', 'dotsThreeCircle'),
];
