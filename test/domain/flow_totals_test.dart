import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';

void main() {
  final usd = currencyOf('USD');
  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    value: RateValue.parse('2800'),
  );
  ExchangeRate? rateFor(String code) => code == 'CDF' ? rate : null;

  test('entries less exits, what is left and the share spent', () {
    final t = flowTotals(usd, const [
      MoneyFlow(incoming: Money(120000, 'USD')),
      MoneyFlow(outgoing: Money(58800, 'USD')),
    ], rateFor);
    expect(t.entries, const Money(120000, 'USD'));
    expect(t.exits, const Money(58800, 'USD'));
    expect(t.rest, const Money(61200, 'USD'));
    expect(t.spentPercent, 49);
    expect(t.approximate, isFalse);
  });

  test('other currencies at the current rate; none without a rate', () {
    final t = flowTotals(usd, const [
      MoneyFlow(outgoing: Money(1400000, 'CDF')),
      MoneyFlow(outgoing: Money(1000, 'EUR')),
    ], rateFor);
    expect(t.exits, const Money(500, 'USD'));
    expect(t.approximate, isTrue, reason: 'the euros have no rate');
  });

  test('no entry: no share spent', () {
    final t = flowTotals(usd, const [
      MoneyFlow(outgoing: Money(500, 'USD')),
    ], rateFor);
    expect(t.spentPercent, isNull);
    expect(t.rest, const Money(-500, 'USD'));
  });
}
