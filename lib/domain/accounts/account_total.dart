import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

/// « Total de mes comptes » in one currency, and the currencies left out
/// for lack of a rate.
class AccountTotal {
  const AccountTotal(this.amount, this.withoutRate);

  final Money amount;

  /// Codes of the currencies with no rate to the total's currency, in the
  /// order met; their accounts show « Pas de taux ».
  final List<String> withoutRate;
}

/// Adds [balances] up in [main], converting the others at the rate
/// [rateFor] gives (a rate between that currency and [main]).
AccountTotal totalIn(
  CurrencyInfo main,
  List<Money> balances,
  ExchangeRate? Function(String code) rateFor,
) {
  var minor = 0;
  final missing = <String>[];
  for (final balance in balances) {
    if (balance.currency == main.code) {
      minor += balance.minor;
      continue;
    }
    final rate = rateFor(balance.currency);
    if (rate == null) {
      if (!missing.contains(balance.currency)) missing.add(balance.currency);
      continue;
    }
    minor += rate.convert(balance, to: main).minor;
  }
  return AccountTotal(Money(minor, main.code), missing);
}
