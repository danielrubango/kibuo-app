import 'package:kibuo/data/transaction_repository.dart';

/// « Refaire » in the + sheet (PRODUCT): the latest operations, newest
/// first, each only once, six at most. Each comes back ready to save again:
/// no note (and the entry starts it today, without attachments).
List<TransactionInfo> redoCandidates(
  List<TransactionInfo> newestFirst, {
  int max = 6,
}) {
  final seen = <String>{};
  final out = <TransactionInfo>[];
  for (final t in newestFirst) {
    final key = [
      t.kind.stored,
      t.accountId,
      t.toAccountId,
      t.categoryId,
      t.paid.minor,
      t.paid.currency,
      t.total.fees.minor,
    ].join('|');
    if (!seen.add(key)) continue;
    out.add(
      TransactionInfo(
        id: t.id,
        kind: t.kind,
        accountId: t.accountId,
        categoryId: t.categoryId,
        toAccountId: t.toAccountId,
        arrived: t.arrived,
        paid: t.paid,
        total: t.total,
        date: t.date,
        rate: t.rate,
        rateTyped: t.rateTyped,
      ),
    );
    if (out.length == max) break;
  }
  return out;
}
