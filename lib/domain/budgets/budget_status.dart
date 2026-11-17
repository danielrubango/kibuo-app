import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

/// A budget's amount from one period on (year × 100 + month).
class AmountChange {
  const AmountChange(this.fromMonth, this.amount);

  final int fromMonth;
  final Money amount;
}

/// The period's key: 202611 for November 2026.
int monthKey(DateTime month) => month.year * 100 + month.month;

/// The amount a budget had in [month]: the last change made at or before
/// it (PRODUCT: the months before a change keep theirs). Null before the
/// budget existed.
Money? amountFor(List<AmountChange> changes, int month) {
  AmountChange? best;
  for (final c in changes) {
    if (c.fromMonth > month) continue;
    if (best == null || c.fromMonth > best.fromMonth) best = c;
  }
  return best?.amount;
}

/// What an expense takes from its budget, in [main] (PRODUCT): what left
/// the account, fees in. Paid in [main] from another account, its frozen
/// rate holds; otherwise the rate of the day. Null without a rate.
Money? expenseInMain({
  required Money total,
  required Money paid,
  required ExchangeRate? frozen,
  required CurrencyInfo main,
  required ExchangeRate? Function(String code) rateFor,
}) {
  if (total.currency == main.code) return total;
  if (paid.currency == main.code && frozen != null) {
    final account = currencyOf(total.currency);
    final converted = frozen.convert(paid, to: account);
    final fees = Money(total.minor - converted.minor, total.currency);
    return Money(paid.minor + frozen.convert(fees, to: main).minor, main.code);
  }
  final rate = rateFor(total.currency);
  return rate?.convert(total, to: main);
}

enum BudgetState {
  /// Under 80 %.
  ok,

  /// From 80 % to the amount itself.
  near,

  /// Past it.
  over,
}

/// A budget in one period: its amount and what was spent.
class BudgetStatus {
  const BudgetStatus({
    required this.amount,
    required this.spent,
    this.approximate = false,
  });

  final Money amount;
  final Money spent;

  /// Some expense had no rate and was left out (« ≈ »).
  final bool approximate;

  Money get left => Money(amount.minor - spent.minor, amount.currency);

  /// Spent as a share of the amount, rounded.
  int get percent =>
      amount.minor <= 0 ? 0 : (spent.minor * 100 / amount.minor).round();

  BudgetState get state => spent.minor > amount.minor
      ? BudgetState.over
      : amount.minor > 0 && spent.minor * 100 >= amount.minor * 80
      ? BudgetState.near
      : BudgetState.ok;
}

/// « À surveiller »: the most used first, then by name.
int watchOrder(BudgetStatus a, String aName, BudgetStatus b, String bName) {
  final byShare = (b.spent.minor * a.amount.minor).compareTo(
    a.spent.minor * b.amount.minor,
  );
  return byShare != 0 ? byShare : aName.compareTo(bName);
}

/// The average offered at creation (PRODUCT): over [spent], the finished
/// periods since the first expense, the last three at most. Null without
/// any expense.
Money? averageOf(List<Money> spent) {
  if (spent.every((m) => m.minor == 0)) return null;
  final last = spent.length > 3 ? spent.sublist(spent.length - 3) : spent;
  final sum = last.fold<int>(0, (s, m) => s + m.minor);
  return Money((sum / last.length).round(), last.first.currency);
}
