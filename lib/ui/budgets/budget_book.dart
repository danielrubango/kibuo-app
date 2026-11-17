import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// One budget in the period shown.
class BudgetLine {
  const BudgetLine({
    required this.budget,
    required this.category,
    required this.status,
  });

  final BudgetInfo budget;
  final CategoryInfo category;
  final BudgetStatus status;
}

/// The budgets of one period, and their sums (canvas Budgets).
class BudgetBook {
  const BudgetBook({
    required this.main,
    required this.period,
    required this.lines,
    required this.categories,
    required this.budgets,
  });

  final CurrencyInfo main;
  final BudgetPeriod period;

  /// Those that existed in the period, in « Mon ordre ».
  final List<BudgetLine> lines;

  /// The top-level expense categories, for the form.
  final List<CategoryInfo> categories;

  /// Every budget, even one made after the period.
  final List<BudgetInfo> budgets;

  Money get amount =>
      Money(lines.fold(0, (s, l) => s + l.status.amount.minor), main.code);
  Money get spent =>
      Money(lines.fold(0, (s, l) => s + l.status.spent.minor), main.code);
  bool get approximate => lines.any((l) => l.status.approximate);

  BudgetStatus get total =>
      BudgetStatus(amount: amount, spent: spent, approximate: approximate);
}

/// Reads what the Budgets page needs for [month] (a period's name).
class BudgetLoader {
  BudgetLoader(this.data, this.budgets);

  final EntryData data;
  final BudgetRepository budgets;

  Future<
    ({
      CurrencyInfo main,
      List<TransactionInfo> ops,
      List<CategoryInfo> categories,
      Map<String, ExchangeRate> rates,
    })
  >
  _base() async {
    final mainCode = await data.currencies.primaryCurrency() ?? 'USD';
    final main = await data.currencies.currency(mainCode);
    final ops = await data.transactions.all();
    final categories = [
      for (final c in await data.categories.categories(CategoryKind.out))
        if (!c.removed && c.parentId == null) c,
    ];
    final rates = <String, ExchangeRate>{};
    for (final code in {for (final t in ops) t.total.total.currency}) {
      if (code == mainCode) continue;
      final rate = await data.currencies.latestRate(mainCode, code);
      if (rate != null) rates[code] = rate.rate;
    }
    return (main: main, ops: ops, categories: categories, rates: rates);
  }

  /// What [category] (and its subcategories) spent in [period], in [main].
  static BudgetStatus _spent(
    CategoryInfo category,
    Money amount,
    BudgetPeriod period,
    List<TransactionInfo> ops,
    CurrencyInfo main,
    Map<String, ExchangeRate> rates,
  ) {
    final ids = {category.id, for (final s in category.subs) s.id};
    var spent = 0;
    var approximate = false;
    for (final t in ops) {
      if (t.kind != EntryKind.expense || !ids.contains(t.categoryId)) {
        continue;
      }
      if (!period.contains(t.date.toLocal())) continue;
      final inMain = expenseInMain(
        total: t.total.total,
        paid: t.paid,
        frozen: t.rate,
        main: main,
        rateFor: (code) => rates[code],
      );
      if (inMain == null) {
        approximate = true;
      } else {
        spent += inMain.minor;
      }
    }
    return BudgetStatus(
      amount: amount,
      spent: Money(spent, main.code),
      approximate: approximate,
    );
  }

  Future<BudgetBook> load(DateTime month) async {
    final base = await _base();
    final period = periodNamed(month);
    final all = await budgets.budgets();
    final lines = <BudgetLine>[];
    for (final b in all) {
      final category = base.categories
          .where((c) => c.id == b.categoryId)
          .firstOrNull;
      // A removed category's budget waits (PRODUCT, backlog).
      if (category == null) continue;
      final amount = amountFor(b.changes, monthKey(period.month));
      if (amount == null) continue;
      lines.add(
        BudgetLine(
          budget: b,
          category: category,
          status: _spent(
            category,
            amount,
            period,
            base.ops,
            base.main,
            base.rates,
          ),
        ),
      );
    }
    return BudgetBook(
      main: base.main,
      period: period,
      lines: lines,
      categories: base.categories,
      budgets: all,
    );
  }

  /// The average offered at creation (PRODUCT): the finished periods since
  /// the category's first expense, the last three at most.
  Future<Money?> average(CategoryInfo category) async {
    final base = await _base();
    final ids = {category.id, for (final s in category.subs) s.id};
    final dates = [
      for (final t in base.ops)
        if (t.kind == EntryKind.expense && ids.contains(t.categoryId))
          t.date.toLocal(),
    ];
    if (dates.isEmpty) return null;
    final first = periodOf(dates.reduce((a, b) => a.isBefore(b) ? a : b));
    final current = periodOf(DateTime.now()).month;
    final spent = <Money>[];
    for (
      var m = first.month;
      m.isBefore(current);
      m = DateTime(m.year, m.month + 1)
    ) {
      spent.add(
        _spent(
          category,
          Money(0, base.main.code),
          periodNamed(m),
          base.ops,
          base.main,
          base.rates,
        ).spent,
      );
    }
    return averageOf(spent);
  }
}
