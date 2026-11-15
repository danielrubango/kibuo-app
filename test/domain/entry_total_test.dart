import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/entry_total.dart';

void main() {
  final usd = currencyOf('USD');
  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    value: RateValue.parse('2800'),
  );

  test('paid in the account’s currency: no conversion', () {
    final t = entryTotal(
      kind: EntryKind.expense,
      paid: const Money(500, 'USD'),
      account: usd,
    );
    expect(t.converted, const Money(500, 'USD'));
    expect(t.total, const Money(500, 'USD'));
  });

  test('an expense in francs is converted, then the fees are added', () {
    final t = entryTotal(
      kind: EntryKind.expense,
      paid: const Money(1400000, 'CDF'),
      account: usd,
      rate: rate,
      fees: 20,
    );
    expect(t.converted, const Money(500, 'USD'), reason: '14 000 FC = 5 \$');
    expect(t.total, const Money(520, 'USD'), reason: 'taken from the account');
  });

  test('an income’s fees are taken off what reaches the account', () {
    final t = entryTotal(
      kind: EntryKind.income,
      paid: const Money(14000000, 'CDF'),
      account: usd,
      rate: rate,
      fees: 50,
    );
    expect(t.converted, const Money(5000, 'USD'));
    expect(t.total, const Money(4950, 'USD'));
  });

  test('another currency needs a rate', () {
    expect(
      () => entryTotal(
        kind: EntryKind.expense,
        paid: const Money(1400000, 'CDF'),
        account: usd,
      ),
      throwsArgumentError,
    );
  });

  test('the change to the account’s balance carries the sign', () {
    expect(
      entryTotal(
        kind: EntryKind.expense,
        paid: const Money(500, 'USD'),
        account: usd,
      ).balanceChange,
      -500,
    );
    expect(
      entryTotal(
        kind: EntryKind.income,
        paid: const Money(500, 'USD'),
        account: usd,
        fees: 50,
      ).balanceChange,
      450,
    );
  });
}
