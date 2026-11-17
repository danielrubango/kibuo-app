import 'package:flutter/foundation.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';

/// « Début du mois », read once at start and changed from Réglages; the
/// list, the home and the month picker follow it.
final monthStartChoice = ValueNotifier<int>(1);

/// The period [day] belongs to, with the chosen start.
BudgetPeriod periodOf(DateTime day) =>
    BudgetPeriod.containing(day, startDay: monthStartChoice.value);

/// The period named [month] (its year and month).
BudgetPeriod periodNamed(DateTime month) => BudgetPeriod.named(
  month.year,
  month.month,
  startDay: monthStartChoice.value,
);
