import 'package:drift/drift.dart';
import 'package:kibuo/data/database.steps.dart';

import 'package:kibuo/domain/sync/hybrid_clock.dart';

part 'database.g.dart';

/// Columns every synced record carries from the first version (ADR 0003):
/// a UUID v7 id, a version from the [HybridClock], the device that made the
/// change, and a deletion flag instead of real deletion.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The phones and other devices that hold the user's data.
class Devices extends Table with SyncColumns {}

/// The currencies the user works with (GLOSSARY: Devise).
class Currencies extends Table with SyncColumns {
  /// ISO 4217 code.
  TextColumn get code => text()();

  /// Decimals in use; amounts stay stored in the smallest ISO unit.
  BoolColumn get usesDecimals => boolean()();
}

/// « 1 [base] = [value] [quote] », typed by the user. A new rate is a new
/// row: the older ones stay, so the previous rate and its date can be shown.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table with SyncColumns {
  TextColumn get base => text()();
  TextColumn get quote => text()();

  /// Exact decimal, as typed: « 2800 », « 655.957 ».
  TextColumn get value => text()();

  DateTimeColumn get setOn => dateTime()();
}

/// The user's choices shared by their devices (the main currency…).
class Preferences extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get value => text()();
}

/// Account types the user created (GLOSSARY: Type de compte). The four
/// provided ones (cash, bank, mobile money, savings) are not rows.
@DataClassName('AccountTypeRow')
class AccountTypes extends Table with SyncColumns {
  TextColumn get name => text()();

  /// The Phosphor icon's name: « users », « house »…
  TextColumn get icon => text()();
}

/// The places where the user's money is (GLOSSARY: Compte).
@DataClassName('AccountRow')
class Accounts extends Table with SyncColumns {
  TextColumn get name => text()();

  /// A provided type (« cash », « bank », « mobile », « savings ») or the id
  /// of an [AccountTypes] row.
  TextColumn get type => text()();

  /// ISO 4217 code; fixed once the account has a transaction.
  TextColumn get currency => text()();

  /// What the account held on [openingDate], in the currency's smallest
  /// unit.
  IntColumn get openingBalance => integer()();
  DateTimeColumn get openingDate => dateTime()();

  /// Out of lists and totals; its transactions stay.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// Order in the lists: one more than the last account at creation.
  IntColumn get position => integer()();
}

/// How operations are classified (GLOSSARY: Catégorie), one level of
/// subcategories at most.
@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  /// « out » for expenses, « in » for income.
  TextColumn get kind => text()();

  /// The category this one belongs to, for a subcategory.
  TextColumn get parentId => text().nullable()();

  /// A provided category's key (« food », « taxi »…), whose name follows
  /// the app's language until the user renames it.
  TextColumn get key => text().nullable()();

  /// The user's own name; null for a provided category never renamed.
  TextColumn get name => text().nullable()();

  /// The Phosphor icon's name.
  TextColumn get icon => text()();

  /// Order among its siblings.
  IntColumn get position => integer()();

  /// Out of the choices; its operations keep it.
  BoolColumn get removed => boolean().withDefault(const Constant(false))();
}

/// Expenses and income (GLOSSARY: Opération). Amounts are positive, in
/// the smallest unit; the kind gives the direction.
@DataClassName('TransactionRow')
class Transactions extends Table with SyncColumns {
  /// « out » for an expense, « in » for an income.
  TextColumn get kind => text()();
  TextColumn get accountId => text()();
  TextColumn get categoryId => text()();

  /// What was paid or received, in [currency].
  IntColumn get amount => integer()();
  TextColumn get currency => text()();

  /// The rate used when [currency] is not the account's, frozen: « 1
  /// [rateBase] = [rateValue] [rateQuote] ».
  TextColumn get rateBase => text().nullable()();
  TextColumn get rateQuote => text().nullable()();
  TextColumn get rateValue => text().nullable()();

  /// Typed for this operation (the changer's), not taken from Devises.
  BoolColumn get rateTyped => boolean().withDefault(const Constant(false))();

  /// [amount] in the account's currency, rounded once and kept.
  IntColumn get converted => integer()();

  /// In the account's currency.
  IntColumn get fees => integer().withDefault(const Constant(0))();

  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(
  tables: [
    Devices,
    Currencies,
    ExchangeRates,
    Preferences,
    AccountTypes,
    Accounts,
    Categories,
    Transactions,
  ],
)
class KibuoDatabase extends _$KibuoDatabase {
  KibuoDatabase(super.executor, {required this.deviceId});

  /// This device, as recorded in the [Devices] table.
  final String deviceId;

  /// Bump with every change to the tables, and add the step to [migration].
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.currencies);
        await m.createTable(schema.exchangeRates);
        await m.createTable(schema.preferences);
      },
      from2To3: (m, schema) async {
        await m.createTable(schema.accountTypes);
        await m.createTable(schema.accounts);
      },
      from3To4: (m, schema) async {
        await m.createTable(schema.categories);
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.transactions);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// The highest version recorded in any table, to restart the clock.
  Future<int> lastVersion() async {
    final rows = await customSelect(
      'SELECT MAX(v) AS v FROM ('
      '${[for (final t in allTables) 'SELECT MAX(version) AS v FROM ${t.actualTableName}'].join(' UNION ALL ')})',
    ).getSingle();
    return rows.read<int?>('v') ?? 0;
  }

  Future<Device> thisDevice() =>
      (select(devices)..where((d) => d.id.equals(deviceId))).getSingle();
}
