import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/accounts/account_total.dart';
import 'package:kibuo/domain/categories/default_categories.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// The figures at the right of « Mes espaces » (canvas Plus).
class PlusSummary {
  const PlusSummary({
    required this.accounts,
    required this.budgets,
    required this.projects,
    required this.debts,
    required this.recurrences,
    required this.categories,
    required this.mainCurrency,
  });

  /// The main currency's code, for the Réglages line.
  final String mainCurrency;

  /// What the accounts hold, in the main currency; null without accounts.
  final Money? accounts;
  final int budgets;

  /// The projects still going on.
  final int projects;

  /// The debts and receivables not settled.
  final int debts;

  /// The recurrences not stopped.
  final int recurrences;

  /// Expense and income categories, not their subcategories.
  final int categories;
}

Future<PlusSummary> loadPlusSummary(KibuoDatabase db, EntryData data) async {
  final accounts = await data.accounts.accounts();
  final mainCode = await data.currencies.primaryCurrency() ?? 'USD';
  final main = await data.currencies.currency(mainCode);
  final rates = <String, ExchangeRate>{};
  for (final code in {
    for (final a in accounts) a.balance.currency,
  }..remove(mainCode)) {
    final rate = await data.currencies.latestRate(mainCode, code);
    if (rate != null) rates[code] = rate.rate;
  }
  final projects = await data.projects?.projects() ?? const [];
  final debts = await data.debts?.debts() ?? const [];
  final rules = await data.recurrences?.rules() ?? const [];
  return PlusSummary(
    mainCurrency: mainCode,
    accounts: accounts.isEmpty
        ? null
        : totalIn(main, [
            for (final a in accounts) a.balance,
          ], (code) => rates[code]).amount,
    budgets: (await BudgetRepository(db).budgets()).length,
    projects: projects.where((p) => p.running).length,
    debts: debts.where((d) => !d.settled).length,
    recurrences: rules.where((r) => !r.stopped).length,
    categories:
        (await data.categories.categories(CategoryKind.out)).length +
        (await data.categories.categories(CategoryKind.into)).length,
  );
}
