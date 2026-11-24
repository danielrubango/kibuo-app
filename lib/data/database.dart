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

  /// Whether the balance may go below zero (GLOSSARY: Découvert).
  BoolColumn get overdraftAllowed =>
      boolean().withDefault(const Constant(false))();

  /// How far below zero, in the currency's smallest unit; null or 0 for no
  /// limit. Kept while [overdraftAllowed] is off.
  IntColumn get overdraftLimit => integer().nullable()();

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
  /// « out » for an expense, « in » for an income, « move » for a
  /// transfer.
  TextColumn get kind => text()();

  /// The account paid from or into; for a transfer, the sending one.
  TextColumn get accountId => text()();

  /// A transfer's receiving account.
  TextColumn get toAccountId => text().nullable()();

  /// None for a transfer.
  TextColumn get categoryId => text().nullable()();

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

  /// [amount] in the account's currency, rounded once and kept; for a
  /// transfer, what reached the receiving account, in its currency.
  IntColumn get converted => integer()();

  /// In the account's currency.
  IntColumn get fees => integer().withDefault(const Constant(0))();

  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  /// « done » counts; « draft » waits for validation and « ignored » was
  /// set aside: neither touches balances nor totals (GLOSSARY: Brouillon).
  TextColumn get status => text().withDefault(const Constant('done'))();

  /// The recurrence it comes from, and the day it fell on (year × 10 000
  /// + month × 100 + day): one occurrence per rule and day.
  TextColumn get recurringId => text().nullable()();
  IntColumn get occurrence => integer().nullable()();

  /// The debt or receivable it opens or repays (GLOSSARY: Dette): its
  /// kind tells which, « in » opening a debt or repaying a receivable.
  TextColumn get debtId => text().nullable()();
}

/// A rule that makes an operation at regular intervals (GLOSSARY:
/// Récurrence); its occurrences are rows of [Transactions].
@DataClassName('RecurringRow')
class RecurringRules extends Table with SyncColumns {
  /// As in [Transactions]: « out », « in » or « move ».
  TextColumn get kind => text()();
  TextColumn get accountId => text()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();

  /// What is paid each time, in [currency].
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
  IntColumn get fees => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();

  /// « day », « week », « month » or « year », every [every].
  TextColumn get unit => text()();
  IntColumn get every => integer().withDefault(const Constant(1))();

  /// For a week: Monday is 1, Sunday 64; at least one day.
  IntColumn get weekdays => integer().withDefault(const Constant(0))();
  DateTimeColumn get start => dateTime()();

  /// The end: after [endCount] times, after [endDate], or never.
  IntColumn get endCount => integer().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// True: always a draft; false: always saved; null: the global setting.
  BoolColumn get asDraft => boolean().nullable()();

  /// The last day already handled, from which catching up goes on.
  DateTimeColumn get doneUntil => dateTime().nullable()();
  BoolColumn get stopped => boolean().withDefault(const Constant(false))();
}

/// Files attached to an operation (ADR 0011): the file itself lives
/// encrypted in `attachments/`, this row describes it.
@DataClassName('AttachmentRow')
class Attachments extends Table with SyncColumns {
  TextColumn get transactionId => text()();
  TextColumn get name => text()();

  /// « photo », « pdf » or « file ».
  TextColumn get kind => text()();

  /// Bytes before encryption.
  IntColumn get size => integer()();

  /// The encrypted file's name in `attachments/`.
  TextColumn get file => text()();
  IntColumn get position => integer()();
}

/// A planned amount for an expense category (GLOSSARY: Budget). Its
/// amount lives in [BudgetAmounts], one row per change.
@DataClassName('BudgetRow')
class Budgets extends Table with SyncColumns {
  /// A top-level expense category; its subcategories count with it.
  TextColumn get categoryId => text()();

  /// « Mon ordre ».
  IntColumn get position => integer()();
}

/// A budget's amount from one period on (PRODUCT: a change holds from the
/// current month, the months before keep theirs).
@DataClassName('BudgetAmountRow')
class BudgetAmounts extends Table with SyncColumns {
  TextColumn get budgetId => text()();

  /// The first period it holds for, as year × 100 + month (202611).
  IntColumn get fromMonth => integer()();

  /// In the currency's minor unit.
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
}

/// Money the user owes someone, or someone owes the user (GLOSSARY:
/// Dette, Créance). Its repayments are rows of [Transactions].
@DataClassName('DebtRow')
class Debts extends Table with SyncColumns {
  /// « owe »: the user owes; « owed »: someone owes the user.
  TextColumn get direction => text()();

  /// The counterparty: a name typed freely (GLOSSARY: Contrepartie).
  TextColumn get person => text()();

  /// What was owed at the start, in [currency], the debt's own; for an old
  /// debt noted without an account, what is left.
  IntColumn get amount => integer()();
  TextColumn get currency => text()();

  /// The day it began.
  DateTimeColumn get openedOn => dateTime()();

  /// None: « Sans échéance ».
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  /// Settled without payment (PRODUCT): what was given up, in [currency],
  /// and when; it can never be taken back.
  IntColumn get forgiven => integer().withDefault(const Constant(0))();
  DateTimeColumn get forgivenOn => dateTime().nullable()();
}

/// A savings goal on one account (GLOSSARY: Projet). The money set aside
/// stays in the account, shown apart as reserved (PRODUCT: Projets).
@DataClassName('ProjectRow')
class Projects extends Table with SyncColumns {
  TextColumn get name => text()();

  /// The Phosphor icon's name.
  TextColumn get icon => text()();
  TextColumn get accountId => text()();

  /// In the account's currency, its minor unit.
  IntColumn get goal => integer()();
  TextColumn get currency => text()();

  /// The day it began: where a dated plan starts from.
  DateTimeColumn get startedOn => dateTime()();

  /// Optional: « Avant le 20 décembre ».
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// « week », « fortnight » or « month »: how its plan is divided.
  TextColumn get period => text().withDefault(const Constant('week'))();

  /// « Me rappeler de mettre de côté ».
  BoolColumn get remind => boolean().withDefault(const Constant(true))();

  /// Ended: « spent » (the expense was noted) or « released » (made
  /// available again); null while running.
  TextColumn get ending => text().nullable()();
  DateTimeColumn get endedOn => dateTime().nullable()();
}

/// Money set aside for a project, or taken back when negative (GLOSSARY:
/// Versement). Nothing moves on the account.
@DataClassName('ContributionRow')
class Contributions extends Table with SyncColumns {
  TextColumn get projectId => text()();

  /// In the project's currency; negative: taken back.
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
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
    Attachments,
    Budgets,
    BudgetAmounts,
    RecurringRules,
    Debts,
    Projects,
    Contributions,
  ],
)
class KibuoDatabase extends _$KibuoDatabase {
  KibuoDatabase(super.executor, {required this.deviceId});

  /// This device, as recorded in the [Devices] table.
  final String deviceId;

  /// Bump with every change to the tables, and add the step to [migration].
  @override
  int get schemaVersion => 13;

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
      from5To6: (m, schema) async {
        await m.createTable(schema.attachments);
      },
      from6To7: (m, schema) async {
        // categoryId becomes optional: SQLite rebuilds the table, rows kept.
        await m.alterTable(
          TableMigration(
            schema.transactions,
            newColumns: [schema.transactions.toAccountId],
          ),
        );
      },
      from7To8: (m, schema) async {
        await m.addColumn(schema.accounts, schema.accounts.overdraftAllowed);
        await m.addColumn(schema.accounts, schema.accounts.overdraftLimit);
      },
      from8To9: (m, schema) async {
        await m.createTable(schema.budgets);
        await m.createTable(schema.budgetAmounts);
      },
      from9To10: (m, schema) async {
        await m.addColumn(schema.transactions, schema.transactions.status);
        await m.addColumn(schema.transactions, schema.transactions.recurringId);
        await m.addColumn(schema.transactions, schema.transactions.occurrence);
        await m.createTable(schema.recurringRules);
      },
      from10To11: (m, schema) async {
        await m.addColumn(schema.transactions, schema.transactions.debtId);
        await m.createTable(schema.debts);
      },
      from11To12: (m, schema) async {
        // A trial build once took some data to 11 without the debts: they
        // come whole here.
        final hasDebts = (await customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'debts'",
        ).get()).isNotEmpty;
        if (!hasDebts) {
          await m.createTable(schema.debts);
        } else {
          await m.addColumn(schema.debts, schema.debts.forgiven);
          await m.addColumn(schema.debts, schema.debts.forgivenOn);
        }
      },
      from12To13: (m, schema) async {
        await m.createTable(schema.projects);
        await m.createTable(schema.contributions);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.versionNow >= 11) await _repairDebts();
    },
  );

  /// A trial build once took some data to version 11 without the debts:
  /// what is missing is added, nothing is removed.
  Future<void> _repairDebts() async {
    Future<bool> has(String sql) async =>
        (await customSelect(sql).get()).isNotEmpty;
    final m = createMigrator();
    if (!await has(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'debts'",
    )) {
      await m.createTable(debts);
    }
    if (!await has(
      "SELECT 1 FROM pragma_table_info('transactions') WHERE name = 'debt_id'",
    )) {
      await m.addColumn(transactions, transactions.debtId);
    }
  }

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
