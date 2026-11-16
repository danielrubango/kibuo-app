import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';

/// What an operation does to each account's balance, by account id: an
/// expense or income to its account, a transfer to both.
Map<String, int> effectsOf(TransactionInfo t) => {
  t.accountId: t.total.balanceChange,
  if (t.toAccountId != null) t.toAccountId!: t.arrived!.minor,
};

/// Why a change can't be saved: [account] would end below its floor
/// (PRODUCT: Découvert).
class OverdraftRefusal {
  const OverdraftRefusal({
    required this.account,
    required this.available,
    required this.after,
  });

  final AccountInfo account;

  /// What may still leave [account] once the old operation is undone.
  final Money available;

  /// Where its balance would end.
  final Money after;
}

/// Checks replacing [before] (an operation dated [beforeDate], or nothing)
/// by [after] (dated [date]) against today's balances. Only a change that
/// lowers an account is checked, so money can always come in; an operation
/// dated before an account's start doesn't touch it.
OverdraftRefusal? checkOverdraft({
  required List<AccountInfo> accounts,
  required Map<String, int> after,
  required DateTime date,
  Map<String, int> before = const {},
  DateTime? beforeDate,
}) {
  for (final account in accounts) {
    int counted(Map<String, int> effects, DateTime? when) =>
        when == null || when.isBefore(account.openingDate)
        ? 0
        : effects[account.id] ?? 0;
    final undone = counted(before, beforeDate);
    final done = counted(after, date);
    if (done - undone >= 0) continue;
    final base = account.balance.minor - undone;
    final end = base + done;
    if (account.overdraft.allows(end)) continue;
    return OverdraftRefusal(
      account: account,
      available: Money(
        account.overdraft.available(base) ?? 0,
        account.currency,
      ),
      after: Money(end, account.currency),
    );
  }
  return null;
}
