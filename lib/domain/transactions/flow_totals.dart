import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

/// What one operation brings in or takes out, in its account's currency
/// (PRODUCT: an expense with its fees out, an income less its fees in, only
/// a transfer's fees out).
class MoneyFlow {
  const MoneyFlow({this.incoming, this.outgoing});

  final Money? incoming;
  final Money? outgoing;
}

/// Entries and exits of a month or a day, in the main currency.
class FlowTotals {
  const FlowTotals({
    required this.entries,
    required this.exits,
    required this.approximate,
  });

  final Money entries;
  final Money exits;

  /// Some operation had no rate to the main currency and was left out
  /// (shown « ≈ »).
  final bool approximate;

  Money get rest => Money(entries.minor - exits.minor, entries.currency);

  /// Exits as a share of entries, rounded; null without any entry.
  int? get spentPercent =>
      entries.minor <= 0 ? null : (exits.minor * 100 / entries.minor).round();
}

FlowTotals flowTotals(
  CurrencyInfo main,
  Iterable<MoneyFlow> flows,
  ExchangeRate? Function(String code) rateFor,
) {
  var approximate = false;
  int inMain(Money? m) {
    if (m == null || m.minor == 0) return 0;
    if (m.currency == main.code) return m.minor;
    final rate = rateFor(m.currency);
    if (rate == null) {
      approximate = true;
      return 0;
    }
    return rate.convert(m, to: main).minor;
  }

  var entries = 0;
  var exits = 0;
  for (final f in flows) {
    entries += inMain(f.incoming);
    exits += inMain(f.outgoing);
  }
  return FlowTotals(
    entries: Money(entries, main.code),
    exits: Money(exits, main.code),
    approximate: approximate,
  );
}
