import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/reminders/due_reminder.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// A recurrence's date to come, with what it does to its account and
/// what it would leave missing (PRODUCT: Rappels).
class DueItem {
  const DueItem({
    required this.planned,
    required this.account,
    required this.amount,
    this.missing,
  });

  final Planned planned;
  final AccountInfo account;

  /// What it moves, as paid.
  final Money amount;

  /// What will be missing on [account], in its currency; null when enough.
  final Money? missing;

  String get key {
    final d = planned.day;
    return 'due:${planned.rule.id}:${d.year * 10000 + d.month * 100 + d.day}';
  }
}

/// The dates to come of every active recurrence, from tomorrow on [now]
/// for [days] days, each with what it would leave missing given today's
/// balances and everything planned before it.
Future<List<DueItem>> dueForecast(
  EntryData data,
  DateTime now, {
  int days = 30,
}) async {
  final recurrences = data.recurrences;
  if (recurrences == null) return const [];
  final today = DateTime(now.year, now.month, now.day);
  final planned = await recurrences.planned(
    now: now,
    until: today.add(Duration(days: days)),
  );
  final accounts = {for (final a in await data.accounts.accounts()) a.id: a};
  final rates = data.currencies;
  final moves = <PlannedMove>[];
  final items = <DueItem>[];
  for (final p in planned) {
    final rule = p.rule;
    final account = accounts[rule.accountId];
    if (account == null) continue;
    // In the account's currency: a missing rate leaves it out.
    var out = rule.amount.minor;
    if (rule.amount.currency != account.currency) {
      final rate = (await rates.latestRate(
        account.currency,
        rule.amount.currency,
      ))?.rate;
      if (rate == null) continue;
      out = rate.convert(rule.amount, to: currencyOf(account.currency)).minor;
    }
    final key = DueItem(planned: p, account: account, amount: rule.amount).key;
    final changes = switch (rule.kind) {
      EntryKind.expense => {account.id: -(out + rule.fees)},
      EntryKind.income => {account.id: out - rule.fees},
      EntryKind.transfer => {
        account.id: -(out + rule.fees),
        if (rule.toAccountId case final to? when accounts[to] != null)
          to: accounts[to]!.currency == account.currency ? out : 0,
      },
    };
    moves.add(PlannedMove(key: key, day: p.day, changes: changes));
    items.add(DueItem(planned: p, account: account, amount: rule.amount));
  }
  final missing = shortfalls(
    balances: {
      for (final a in accounts.values) a.id: (a.balance.minor, a.overdraft),
    },
    moves: moves,
  );
  return [
    for (final i in items)
      DueItem(
        planned: i.planned,
        account: i.account,
        amount: i.amount,
        missing: missing[i.key] == null
            ? null
            : Money(missing[i.key]!, i.account.currency),
      ),
  ];
}

/// A recurrence's name, as its list shows it: its note, or its category,
/// or « vers Épargne » for a transfer.
Future<String Function(DueItem)> dueNames(
  EntryData data,
  AppLocalizations l,
) async {
  final categories = [
    ...await data.categories.categories(CategoryKind.out),
    ...await data.categories.categories(CategoryKind.into),
  ];
  final all = {
    for (final c in categories) ...{
      c.id: c,
      for (final sub in c.subs) sub.id: sub,
    },
  };
  final accounts = {
    for (final a in await data.accounts.accounts()) a.id: a.name,
  };
  return (DueItem item) {
    final rule = item.planned.rule;
    final note = rule.note?.trim() ?? '';
    if (note.isNotEmpty) return note;
    if (rule.kind == EntryKind.transfer) {
      return l.recurrenceToAccount(accounts[rule.toAccountId] ?? '');
    }
    final category = all[rule.categoryId];
    return category == null ? '' : categoryName(l, category);
  };
}
