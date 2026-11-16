import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/ui/transactions/overdraft_check.dart';

void main() {
  final start = DateTime.utc(2026, 11, 1);
  final today = DateTime.utc(2026, 11, 16);
  AccountInfo account(
    String id,
    int balance, {
    Overdraft overdraft = Overdraft.none,
  }) => AccountInfo(
    id: id,
    name: id,
    type: AccountType.mobile,
    opening: const Money(0, 'USD'),
    openingDate: start,
    balance: Money(balance, 'USD'),
    archived: false,
    overdraft: overdraft,
  );

  test('an expense above what is left is refused, with what is left', () {
    final r = checkOverdraft(
      accounts: [account('mpesa', 4500)],
      after: {'mpesa': -6000},
      date: today,
    );
    expect(r!.account.id, 'mpesa');
    expect(r.available, const Money(4500, 'USD'));
    expect(r.after, const Money(-1500, 'USD'));
  });

  test('down to the limit, then refused past it', () {
    final bank = account(
      'bank',
      4500,
      overdraft: const Overdraft(allowed: true, limit: 10000),
    );
    expect(
      checkOverdraft(accounts: [bank], after: {'bank': -14500}, date: today),
      isNull,
    );
    expect(
      checkOverdraft(accounts: [bank], after: {'bank': -14501}, date: today),
      isNotNull,
    );
  });

  test('editing an expense does not count it twice', () {
    // 45 $ left after a 60 $ expense: 105 $ may go, so 110 $ can't.
    final r = checkOverdraft(
      accounts: [account('mpesa', 4500)],
      before: {'mpesa': -6000},
      beforeDate: today,
      after: {'mpesa': -11000},
      date: today,
    );
    expect(r!.available, const Money(10500, 'USD'));
  });

  test('money coming in always passes, even below zero', () {
    expect(
      checkOverdraft(
        accounts: [account('mpesa', -2000)],
        after: {'mpesa': 500},
        date: today,
      ),
      isNull,
    );
  });

  test('deleting an income that the balance needs is refused', () {
    final r = checkOverdraft(
      accounts: [account('mpesa', 4500)],
      before: {'mpesa': 9000},
      beforeDate: today,
      after: const {},
      date: today,
    );
    expect(r!.after, const Money(-4500, 'USD'));
  });

  test('a transfer checks the sender, and what the receiver loses', () {
    final r = checkOverdraft(
      accounts: [account('mpesa', 10000), account('savings', 1000)],
      before: {'mpesa': -5000, 'savings': 5000},
      beforeDate: today,
      after: {'mpesa': -2000, 'savings': 2000},
      date: today,
    );
    expect(r!.account.id, 'savings', reason: 'it would end at −20 \$');
  });

  test('before the account’s start, an operation does not touch it', () {
    expect(
      checkOverdraft(
        accounts: [account('mpesa', 0)],
        after: {'mpesa': -6000},
        date: DateTime.utc(2026, 10, 20),
      ),
      isNull,
    );
  });
}
