import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';

void main() {
  late KibuoDatabase db;
  late CurrencyRepository repo;
  var now = DateTime.utc(2026, 11, 3, 9);

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    repo = CurrencyRepository(db, now: () => now);
    now = DateTime.utc(2026, 11, 3, 9);
  });
  tearDown(() => db.close());

  test('the main currency is set once, from the phone, then kept', () async {
    expect(await repo.primaryCurrency(), isNull);

    await repo.ensurePrimaryCurrency('CD');
    expect(await repo.primaryCurrency(), 'CDF');
    expect(await repo.currencyCodes(), ['CDF']);

    await repo.ensurePrimaryCurrency('US');
    expect(await repo.primaryCurrency(), 'CDF', reason: 'never overwritten');
  });

  test('changing the main currency adds it to the list', () async {
    await repo.ensurePrimaryCurrency('US');
    await repo.setPrimaryCurrency('EUR');

    expect(await repo.primaryCurrency(), 'EUR');
    expect(await repo.currencyCodes(), containsAll(['USD', 'EUR']));
  });

  test('a currency is added once', () async {
    await repo.addCurrency('CDF');
    await repo.addCurrency('CDF');

    expect(await repo.currencyCodes(), ['CDF']);
  });

  test('decimals can be turned off and on for a currency', () async {
    await repo.addCurrency('USD');
    expect((await repo.currency('USD')).usesDecimals, isTrue);

    await repo.setUsesDecimals('USD', on: false);
    expect((await repo.currency('USD')).usesDecimals, isFalse);
  });

  test('a new rate is added, the old one kept with its date', () async {
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));
    now = DateTime.utc(2026, 11, 15, 9);
    await repo.setRate('USD', 'CDF', RateValue.parse('2850'));

    final current = (await repo.latestRate('USD', 'CDF'))!;
    expect(current.rate.value, RateValue.parse('2850'));
    expect(current.setOn, DateTime.utc(2026, 11, 15, 9));
    expect(current.previous!.rate.value, RateValue.parse('2800'));
    expect(current.previous!.setOn, DateTime.utc(2026, 11, 3, 9));
  });

  test('a rate is found whichever way it was typed', () async {
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));

    final rate = (await repo.latestRate('CDF', 'USD'))!.rate;
    expect((rate.base, rate.quote), ('USD', 'CDF'));
  });

  test(
    'without a direct rate, one is worked out through a third currency',
    () async {
      await repo.setRate('USD', 'CDF', RateValue.parse('2800'));
      await repo.setRate('USD', 'EUR', RateValue.parse('0.8'));

      final cross = (await repo.latestRate('EUR', 'CDF'))!;
      expect(cross.isWorkedOut, isTrue);
      expect(cross.rate.forDisplay().value, RateValue.parse('3500'));
    },
  );

  test('no rate at all gives nothing', () async {
    expect(await repo.latestRate('USD', 'CDF'), isNull);
  });

  test('every record carries its sync metadata', () async {
    await repo.ensurePrimaryCurrency('CD');
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));

    final rates = await db.select(db.exchangeRates).get();
    final currencies = await db.select(db.currencies).get();
    for (final (id, version, device) in [
      for (final r in rates) (r.id, r.version, r.deviceId),
      for (final c in currencies) (c.id, c.version, c.deviceId),
    ]) {
      expect(id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(version, greaterThan(0));
      expect(device, 'phone-1');
    }
    final versions = [
      ...rates.map((r) => r.version),
      ...currencies.map((c) => c.version),
    ];
    expect(versions.toSet(), hasLength(versions.length));
  });
}
