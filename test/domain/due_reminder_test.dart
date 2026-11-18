import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/accounts/overdraft.dart';
import 'package:kibuo/domain/reminders/due_reminder.dart';

void main() {
  test('a reminder at 9:00, some days before', () {
    expect(
      reminderAt(DateTime(2026, 11, 25, 12), 3),
      DateTime(2026, 11, 22, 9),
    );
    expect(reminderAt(DateTime(2026, 11, 25), 0), DateTime(2026, 11, 25, 9));
  });

  test('what will be missing, with what comes in and goes out before', () {
    final missing = shortfalls(
      balances: {'mpesa': (100000, Overdraft.none)},
      moves: [
        PlannedMove(
          key: 'salaire',
          day: DateTime(2026, 11, 24),
          changes: {'mpesa': 50000},
        ),
        PlannedMove(
          key: 'internet',
          day: DateTime(2026, 11, 22),
          changes: {'mpesa': -30000},
        ),
        PlannedMove(
          key: 'loyer',
          day: DateTime(2026, 11, 25),
          changes: {'mpesa': -250000},
        ),
      ],
    );
    // 100 000 − 30 000 + 50 000 = 120 000 before the rent.
    expect(missing, {'loyer': 130000});
  });

  test('an allowed overdraft lowers the floor; transfers move both ways', () {
    final missing = shortfalls(
      balances: {
        'mpesa': (10000, const Overdraft(allowed: true, limit: 20000)),
        'savings': (0, Overdraft.none),
      },
      moves: [
        PlannedMove(
          key: 'courses',
          day: DateTime(2026, 11, 20),
          changes: {'mpesa': -25000},
        ),
        PlannedMove(
          key: 'epargne',
          day: DateTime(2026, 11, 21),
          changes: {'mpesa': -10000, 'savings': 10000},
        ),
      ],
    );
    // −15 000 is fine (limit 20 000); −25 000 is 5 000 too far.
    expect(missing, {'epargne': 5000});
  });

  test('money going in never misses anything', () {
    expect(
      shortfalls(
        balances: {'mpesa': (-5000, Overdraft.none)},
        moves: [
          PlannedMove(
            key: 'vente',
            day: DateTime(2026, 11, 20),
            changes: {'mpesa': 1000},
          ),
        ],
      ),
      isEmpty,
    );
  });
}
