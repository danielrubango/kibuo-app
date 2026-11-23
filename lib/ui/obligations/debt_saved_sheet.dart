import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/auto_close.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// What the new debt form saved: the debt, and the account its money
/// moved on, if any.
class SavedDebt {
  const SavedDebt({required this.id, required this.direction, this.account});

  final String id;
  final DebtDirection direction;
  final String? account;
}

/// « Dette enregistrée » (owner, 23 November): like a saved operation, it
/// closes by itself, or at once with ✕; « Nouvelle dette » starts another.
/// Returns true for another.
Future<bool?> showDebtSavedSheet(
  BuildContext context,
  DebtLine debt, {
  String? account,
}) => showModalBottomSheet<bool>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => withSheetHandle(_DebtSaved(debt: debt, account: account)),
);

class _DebtSaved extends StatelessWidget {
  const _DebtSaved({required this.debt, this.account});

  final DebtLine debt;
  final String? account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final owe = debt.direction == DebtDirection.owe;
    final due = debt.due;
    final where = [
      account ?? l.debtNoAccount,
      due == null
          ? l.debtsNoDue
          : l.debtDueLine(DateFormat.MMMd(lang).format(due)),
    ].join(' · ');
    return Padding(
      padding: sheetPadding(context),
      child: AutoClose(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: owe ? l.debtSavedOwe : l.debtSavedOwed),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: KibuoColors.mint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(KibuoIcons.check, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.person,
                          style: KibuoType.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          where,
                          style: KibuoType.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatMoney(
                      debt.amount,
                      currencyOf(debt.amount.currency),
                      lang,
                    ),
                    style: KibuoType.cardTitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            KibuoButton(
              label: owe ? l.debtNewOwe : l.debtNewOwed,
              kind: ButtonKind.secondary,
              icon: KibuoIcons.plusBold,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
