import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';

/// A planned date as the list shows it: an operation that is not one
/// yet, carrying its recurrence's id.
TransactionInfo plannedOperation(Planned p) {
  final rule = p.rule;
  return TransactionInfo(
    id: rule.id,
    kind: rule.kind,
    accountId: rule.accountId,
    toAccountId: rule.toAccountId,
    categoryId: rule.categoryId,
    paid: rule.amount,
    arrived: rule.kind == EntryKind.transfer ? rule.amount : null,
    total: EntryTotal(
      kind: rule.kind,
      converted: rule.amount,
      fees: Money(rule.fees, rule.amount.currency),
    ),
    date: DateTime(p.day.year, p.day.month, p.day.day, 12),
    note: rule.note,
    status: 'planned',
    recurringId: rule.id,
  );
}
