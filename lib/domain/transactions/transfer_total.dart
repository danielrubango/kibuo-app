import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

/// What a transfer does to its two accounts (GLOSSARY: Transfert). The
/// amount is in the sending account's currency, and so are the fees
/// (PRODUCT).
class TransferTotal {
  const TransferTotal({
    required this.sent,
    required this.fees,
    required this.arrived,
  });

  /// What was sent, in the sending account's currency.
  final Money sent;

  /// In the sending account's currency.
  final Money fees;

  /// What reaches the receiving account, in its currency.
  final Money arrived;

  /// Taken from the sending account: what was sent, plus the fees.
  Money get withdrawn => Money(sent.minor + fees.minor, sent.currency);
}

TransferTotal transferTotal({
  required Money sent,
  required CurrencyInfo to,
  ExchangeRate? rate,
  int fees = 0,
}) {
  final Money arrived;
  if (sent.currency == to.code) {
    arrived = sent;
  } else if (rate == null) {
    throw ArgumentError.value(rate, 'rate', 'needed for ${to.code}');
  } else {
    arrived = rate.convert(sent, to: to);
  }
  return TransferTotal(
    sent: sent,
    fees: Money(fees, sent.currency),
    arrived: arrived,
  );
}
