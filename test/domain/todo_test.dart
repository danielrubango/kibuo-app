import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/todo/todo.dart';

void main() {
  final today = DateTime(2026, 11, 18, 15);

  TodoItem item(TodoKind kind, [String key = '']) =>
      TodoItem(kind: kind, key: '${kind.name}$key');

  test('the most urgent first, by group then by kind', () {
    final sorted = sortTodos([
      item(TodoKind.oldRate),
      item(TodoKind.budgetNear),
      item(TodoKind.drafts),
      item(TodoKind.recovery),
      item(TodoKind.budgetOver),
    ]);
    expect(
      [for (final t in sorted) t.kind],
      [
        TodoKind.budgetOver,
        TodoKind.recovery,
        TodoKind.drafts,
        TodoKind.budgetNear,
        TodoKind.oldRate,
      ],
    );
    expect(
      [for (final t in sorted) t.group],
      [
        TodoGroup.urgent,
        TodoGroup.urgent,
        TodoGroup.week,
        TodoGroup.week,
        TodoGroup.reminders,
      ],
    );
  });

  test('an old backup is a reminder, before late projects and rates', () {
    final sorted = sortTodos([
      item(TodoKind.oldRate),
      item(TodoKind.projectLate),
      item(TodoKind.backupOld),
      item(TodoKind.budgetNear),
    ]);
    expect(
      [for (final t in sorted) t.kind],
      [
        TodoKind.budgetNear,
        TodoKind.backupOld,
        TodoKind.projectLate,
        TodoKind.oldRate,
      ],
    );
    expect(TodoKind.backupOld.group, TodoGroup.reminders);
  });

  test('the dot takes the most urgent group present', () {
    expect(mostUrgent([item(TodoKind.oldRate)]), TodoGroup.reminders);
    expect(
      mostUrgent([item(TodoKind.oldRate), item(TodoKind.drafts)]),
      TodoGroup.week,
    );
    expect(mostUrgent(const []), isNull);
  });

  test('put off today: hidden until tomorrow, whatever the hour', () {
    final later = PutOff.empty.add('budgetOverA', today);
    final shown = later.visible([
      item(TodoKind.budgetOver, 'A'),
      item(TodoKind.budgetOver, 'B'),
    ], today);
    expect([for (final t in shown) t.key], ['budgetOverB']);
    final tomorrow = DateTime(2026, 11, 19, 0, 1);
    expect(
      later.visible([item(TodoKind.budgetOver, 'A')], tomorrow),
      hasLength(1),
    );
  });

  test('put off: undone, and kept as text', () {
    final later = PutOff.empty.add('drafts', today);
    expect(
      PutOff.parse(later.encode()).visible([item(TodoKind.drafts, '')], today),
      isEmpty,
    );
    expect(
      later.remove('drafts').visible([item(TodoKind.drafts, '')], today),
      hasLength(1),
    );
    expect(
      PutOff.parse(null).visible([item(TodoKind.drafts, '')], today),
      hasLength(1),
    );
    expect(
      PutOff.parse('not json').visible([item(TodoKind.drafts, '')], today),
      hasLength(1),
    );
  });

  test('a rate is old after 30 days', () {
    expect(rateIsOld(DateTime(2026, 10, 20), today), isFalse);
    expect(rateIsOld(DateTime(2026, 10, 19), today), isTrue);
  });
}
