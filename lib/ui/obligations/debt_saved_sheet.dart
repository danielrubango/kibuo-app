import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/confirm_sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';

/// What the new debt form saved: the debt, and the account its money
/// moved on, if any.
class SavedDebt {
  const SavedDebt({required this.id, required this.direction, this.account});

  final String id;
  final DebtDirection direction;
  final String? account;
}

/// « Dette enregistrée » (owner, 23 November): the shared confirmation
/// sheet; « Nouvelle dette » starts another. Returns true for another.
Future<bool?> showDebtSavedSheet(
  BuildContext context,
  DebtLine debt, {
  String? account,
}) {
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final owe = debt.direction == DebtDirection.owe;
  final due = debt.due;
  return showConfirmSheet<bool>(
    context,
    title: owe ? l.debtSavedOwe : l.debtSavedOwed,
    card: SavedLine(
      title: debt.person,
      subtitle: [
        account ?? l.debtNoAccount,
        due == null
            ? l.debtsNoDue
            : l.debtDueLine(DateFormat.MMMd(lang).format(due)),
      ].join(' · '),
      amount: formatMoney(debt.amount, currencyOf(debt.amount.currency), lang),
    ),
    actions: [
      ConfirmAction(owe ? l.debtNewOwe : l.debtNewOwed, true, main: true),
    ],
  );
}
