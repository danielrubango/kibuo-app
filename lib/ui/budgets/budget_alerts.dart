import 'package:flutter/material.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/domain/budgets/budget_alert.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/budgets/budget_detail_screen.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';

/// Alertes de budget (PRODUCT): a message when a budget crosses 80 % or
/// 100 %, once a threshold, a budget and a month.
class BudgetAlerts {
  BudgetAlerts({required this.loader, required this.store});

  final BudgetLoader loader;
  final ReminderStore store;

  Future<(BudgetBook, List<Crossing>, int)> _crossings(DateTime now) async {
    final month = periodOf(now).month;
    final key = monthKey(month);
    final book = await loader.load(month);
    final crossed = crossings(
      month: key,
      budgets: {
        for (final line in book.lines)
          line.budget.id: (
            spent: line.status.spent.minor,
            amount: line.status.amount.minor,
          ),
      },
      alerted: await store.budgetAlerted(),
      at80: await store.budgetAt80(),
      at100: await store.budgetAt100(),
    );
    return (book, crossed, key);
  }

  /// What is crossed already, said in silence: at opening, before the
  /// recurrences arrive.
  Future<void> settle(DateTime now) async {
    final (_, crossed, month) = await _crossings(now);
    await store.addBudgetAlerted([for (final c in crossed) ...c.covers], month);
  }

  /// Says the most touched budget newly crossed, if any; the others are
  /// settled with it, so messages never stack.
  Future<void> check(BuildContext context, DateTime now) async {
    final (book, crossed, month) = await _crossings(now);
    final best = mostTouched(crossed);
    if (best == null) return;
    await store.addBudgetAlerted([for (final c in crossed) ...c.covers], month);
    final line = book.lines.firstWhere((l) => l.budget.id == best.budgetId);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    String money(Money m) => formatMoney(
      Money(m.minor.abs(), m.currency),
      currencyOf(m.currency),
      lang,
    );
    final name = categoryName(l, line.category);
    final left = line.status.left;
    final text = best.threshold == 80
        ? l.budgetAlertNear(name, '${best.percent}', money(left))
        : left.minor < 0
        ? l.budgetAlertOver(name, money(left))
        : l.budgetAlertFull(name);
    final navigator = Navigator.of(context);
    showKibuoToast(
      context,
      text,
      action: l.budgetAlertSee,
      onAction: () => navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => BudgetDetailScreen(
            loader: loader,
            month: book.period.month,
            budgetId: line.budget.id,
          ),
        ),
      ),
    );
  }
}
