import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

/// An expense or an income (GLOSSARY: Dépense, Revenu).
enum EntryKind {
  expense,
  income;

  String get stored => this == expense ? 'out' : 'in';

  static EntryKind fromStored(String s) => s == 'in' ? income : expense;
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

  /// Taken from the account (expense: amount plus fees) or added to it
  /// (income: amount less fees).
  Money get total => kind == EntryKind.expense
      ? Money(converted.minor + fees.minor, converted.currency)
      : Money(converted.minor - fees.minor, converted.currency);

  /// The change to the account's balance, with its sign.
  int get balanceChange =>
      kind == EntryKind.expense ? -total.minor : total.minor;
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
