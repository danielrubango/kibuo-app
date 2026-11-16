import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/transfer_total.dart';

void main() {
  final usd = currencyOf('USD');
  final cdf = currencyOf('CDF');
  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    value: RateValue.parse('2850'),
  );

  test('between two accounts in dollars: what leaves arrives', () {
    final t = transferTotal(sent: const Money(5000, 'USD'), to: usd);
    expect(t.withdrawn, const Money(5000, 'USD'));
    expect(t.arrived, const Money(5000, 'USD'));
  });

  test('to an account in francs: converted at the frozen rate', () {
    final t = transferTotal(
      sent: const Money(5000, 'USD'),
      to: cdf,
      rate: rate,
    );
    expect(
      t.arrived,
      const Money(14250000, 'CDF'),
      reason: '50 \$ = 142 500 FC',
    );
  });

  test('fees, in the sending currency, add to what leaves only', () {
    final t = transferTotal(
      sent: const Money(5000, 'USD'),
      to: cdf,
      rate: rate,
      fees: 20,
    );
    expect(t.withdrawn, const Money(5020, 'USD'));
    expect(t.fees, const Money(20, 'USD'));
    expect(t.arrived, const Money(14250000, 'CDF'));
  });

  test('another currency needs a rate', () {
    expect(
      () => transferTotal(sent: const Money(5000, 'USD'), to: cdf),
      throwsArgumentError,
    );
  });
}
