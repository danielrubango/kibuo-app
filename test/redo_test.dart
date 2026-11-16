import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/ui/transactions/redo.dart';

TransactionInfo op(
  String id, {
  String category = 'default-taxi',
  int minor = 500,
  String account = 'mpesa',
  EntryKind kind = EntryKind.expense,
}) => TransactionInfo(
  id: id,
  kind: kind,
  accountId: account,
  categoryId: category,
  paid: Money(minor, 'USD'),
  total: EntryTotal(
    kind: kind,
    converted: Money(minor, 'USD'),
    fees: const Money(0, 'USD'),
  ),
  date: DateTime.utc(2026, 11, 16),
  note: 'une note',
);

void main() {
  test('the latest first, without the same operation twice', () {
    final list = redoCandidates([
      op('a'),
      op('b'),
      op('c', minor: 700),
      op('d', category: 'default-food'),
    ]);
    expect([for (final t in list) t.id], ['a', 'c', 'd']);
  });

  test('six at most', () {
    final list = redoCandidates([
      for (var i = 0; i < 9; i++) op('$i', minor: 100 + i),
    ]);
    expect(list, hasLength(6));
  });

  test('ready to save again: no note, nothing else kept', () {
    final again = redoCandidates([op('a')]).single;
    expect(again.note, isNull);
    expect(again.paid, const Money(500, 'USD'));
  });
}
