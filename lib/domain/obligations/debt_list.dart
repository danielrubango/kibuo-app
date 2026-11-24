import 'package:kibuo/domain/calendar.dart';
import 'package:kibuo/domain/money/money.dart';

/// Who owes (GLOSSARY: Dette, Créance).
enum DebtDirection {
  /// The user owes someone.
  owe('owe'),

  /// Someone owes the user.
  owed('owed');

  const DebtDirection(this.stored);

  final String stored;

  static DebtDirection fromStored(String value) =>
      values.firstWhere((d) => d.stored == value);
}

/// A debt or receivable as the list shows it.
class DebtLine {
  const DebtLine({
    required this.id,
    required this.direction,
    required this.person,
    required this.amount,
    required this.left,
    this.due,
    this.settledOn,
    this.forgiven,
  });

  final String id;
  final DebtDirection direction;
  final String person;

  /// What was owed at the start, in the debt's own currency.
  final Money amount;

  /// What is still owed, in the same currency.
  final Money left;

  /// None: « Sans échéance ».
  final DateTime? due;

  /// The last repayment's day, once nothing is left; or the day it was
  /// settled without payment.
  final DateTime? settledOn;

  /// What was given up when settled without payment.
  final Money? forgiven;

  bool get forgivenSettled => forgiven != null && forgiven!.minor > 0;

  bool get settled => left.minor <= 0;

  /// From 0, nothing paid back, to 1, settled.
  double get repaidShare => amount.minor <= 0
      ? 1
      : ((amount.minor - left.minor) / amount.minor).clamp(0, 1);
}

/// What the colour and the words of a line tell (canvas DettesListeDois).
enum DebtState { late, today, soon, normal, none, paid }

/// Its state and the days from [now]'s day to its due day (negative when
/// late), or null without a date. Tomorrow and the day after are « soon ».
(DebtState, int?) debtState(DebtLine debt, DateTime now) {
  final due = debt.due;
  final days = due == null ? null : _days(_day(now), _day(due));
  if (debt.settled) return (DebtState.paid, days);
  if (days == null) return (DebtState.none, null);
  if (days < 0) return (DebtState.late, days);
  if (days == 0) return (DebtState.today, days);
  if (days <= 2) return (DebtState.soon, days);
  return (DebtState.normal, days);
}

/// How the list groups its lines (the display sheet's choice).
enum DebtGrouping { due, person }

/// Where settled lines go (PRODUCT: Dettes et créances).
enum PaidPlace {
  /// With the others, at their date; without a date, in « Sans échéance ».
  inline('inline'),

  /// In a block of their own, at the bottom.
  bottom('bottom'),

  /// Not in the list.
  hidden('hidden');

  const PaidPlace(this.stored);

  final String stored;

  static PaidPlace fromStored(String? value) =>
      values.firstWhere((p) => p.stored == value, orElse: () => inline);
}

/// What a group gathers: the late ones, a month, no date, or a person.
class DebtGroupKey {
  const DebtGroupKey.late() : kind = 'late', year = 0, month = 0, person = '';
  const DebtGroupKey.none() : kind = 'none', year = 0, month = 0, person = '';
  const DebtGroupKey.month(this.year, this.month) : kind = 'month', person = '';
  const DebtGroupKey.person(this.person) : kind = 'person', year = 0, month = 0;

  final String kind;
  final int year;
  final int month;
  final String person;

  bool get isLate => kind == 'late';
  bool get isNone => kind == 'none';
  bool get isMonth => kind == 'month';
  bool get isPerson => kind == 'person';

  @override
  bool operator ==(Object other) =>
      other is DebtGroupKey &&
      other.kind == kind &&
      other.year == year &&
      other.month == month &&
      other.person == person;

  @override
  int get hashCode => Object.hash(kind, year, month, person);

  @override
  String toString() => 'DebtGroupKey($kind $year-$month $person)';
}

class DebtGroup {
  const DebtGroup(this.key, this.lines);

  final DebtGroupKey key;
  final List<DebtLine> lines;
}

class DebtListing {
  const DebtListing(this.groups, this.paid);

  final List<DebtGroup> groups;

  /// The settled ones, when they go at the bottom.
  final List<DebtLine> paid;
}

/// The list (PRODUCT: Dettes et créances): by due date, the closest first,
/// the late ones on top, « Sans échéance » at the bottom; or one group per
/// person, in alphabetical order.
DebtListing arrangeDebts(
  List<DebtLine> lines, {
  required DateTime today,
  DebtGrouping grouping = DebtGrouping.due,
  PaidPlace paidPlace = PaidPlace.inline,
}) {
  final shown = [
    for (final l in lines)
      if (!l.settled || paidPlace == PaidPlace.inline) l,
  ]..sort(_byDue);
  final paid = paidPlace == PaidPlace.bottom
      ? ([
          for (final l in lines)
            if (l.settled) l,
        ]..sort(_byDue))
      : const <DebtLine>[];
  if (grouping == DebtGrouping.person) {
    final byName = <String, List<DebtLine>>{};
    for (final l in shown) {
      byName.putIfAbsent(_fold(l.person), () => []).add(l);
    }
    final names = byName.keys.toList()..sort();
    return DebtListing([
      for (final n in names)
        DebtGroup(DebtGroupKey.person(byName[n]!.first.person), byName[n]!),
    ], paid);
  }
  final groups = <DebtGroupKey, List<DebtLine>>{};
  final day = _day(today);
  for (final l in shown) {
    final due = l.due;
    final key = due == null
        ? const DebtGroupKey.none()
        : !l.settled && _day(due).isBefore(day)
        ? const DebtGroupKey.late()
        : DebtGroupKey.month(due.year, due.month);
    groups.putIfAbsent(key, () => []).add(l);
  }
  int rank(DebtGroupKey k) => k.isLate
      ? 0
      : k.isNone
      ? 999999
      : k.year * 12 + k.month;
  final keys = groups.keys.toList()..sort((a, b) => rank(a) - rank(b));
  return DebtListing([for (final k in keys) DebtGroup(k, groups[k]!)], paid);
}

int _byDue(DebtLine a, DebtLine b) {
  final da = a.due;
  final db = b.due;
  if (da == null && db == null) {
    return _fold(a.person).compareTo(_fold(b.person));
  }
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

int _days(DateTime from, DateTime to) => calendarDays(from, to);

/// For sorting and matching names: lower case, without accents.
String _fold(String name) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final out = StringBuffer();
  for (final c in name.trim().toLowerCase().split('')) {
    final i = from.indexOf(c);
    if (c == 'œ') {
      out.write('oe');
    } else if (c == 'æ') {
      out.write('ae');
    } else {
      out.write(i >= 0 && i < to.length ? to[i] : c);
    }
  }
  return out.toString();
}

/// A name as typed and matched: the same person whatever the case or the
/// accents.
String debtPersonKey(String name) => _fold(name);
