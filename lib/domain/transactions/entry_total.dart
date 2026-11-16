import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

/// An expense, an income or a transfer (GLOSSARY: Dépense, Revenu,
/// Transfert).
enum EntryKind {
  expense('out'),
  income('in'),
  transfer('move');

  const EntryKind(this.stored);

  final String stored;

  static EntryKind fromStored(String s) =>
      values.firstWhere((k) => k.stored == s, orElse: () => expense);
}

/// What an expense or income does to its account (PRODUCT: « le décompte »):
/// the amount paid, converted into the account's currency, then the fees.
class EntryTotal {
  const EntryTotal({
    required this.kind,
    required this.converted,
    required this.fees,
  });

  final EntryKind kind;

  /// The amount paid, in the account's currency.
  final Money converted;

  /// Always in the account's currency.
  final Money fees;

  /// Added to the account (income: amount less fees) or taken from it
  /// (expense, and a transfer's sending account: amount plus fees).
  Money get total => kind == EntryKind.income
      ? Money(converted.minor - fees.minor, converted.currency)
      : Money(converted.minor + fees.minor, converted.currency);

  /// The change to the account's balance, with its sign.
  int get balanceChange =>
      kind == EntryKind.income ? total.minor : -total.minor;
}

EntryTotal entryTotal({
  required EntryKind kind,
  required Money paid,
  required CurrencyInfo account,
  ExchangeRate? rate,
  int fees = 0,
}) {
  final Money converted;
  if (paid.currency == account.code) {
    converted = paid;
  } else if (rate == null) {
    throw ArgumentError.value(rate, 'rate', 'needed for ${paid.currency}');
  } else {
    converted = rate.convert(paid, to: account);
  }
  return EntryTotal(
    kind: kind,
    converted: converted,
    fees: Money(fees, account.code),
  );
}
