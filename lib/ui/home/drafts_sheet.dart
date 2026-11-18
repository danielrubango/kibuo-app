import 'package:flutter/material.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/day_header.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/draft_screen.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/overdraft_check.dart';

/// « 2 brouillons à valider » (canvas BrouS1, BrouS1Un): each draft
/// checked in advance, except one a rate or a floor holds back, which says
/// why; touching a draft opens its card; « Valider les 2 » confirms those
/// checked, « Plus tard » closes without a change (PRODUCT).
Future<void> showDraftsSheet(
  BuildContext context,
  EntryData data,
  List<(TransactionInfo, OperationLabels)> drafts,
) async {
  final l = AppLocalizations.of(context);
  final accounts = await data.accounts.accounts();
  String? why(TransactionInfo t, OperationLabels labels) {
    if (waitsForRate(t, labels)) return l.draftsSheetNoRate;
    final refusal = checkOverdraft(
      accounts: accounts,
      after: effectsOf(t),
      date: t.date,
    );
    return refusal == null ? null : l.draftsSheetFloor;
  }

  if (!context.mounted) return;
  final rows = [for (final (t, labels) in drafts) (t, labels, why(t, labels))];
  final chosen = await showKibuoSheet<List<String>>(
    context,
    title: l.draftsSheetTitle(rows.length),
    builder: (context) => _DraftsPicker(data: data, rows: rows),
  );
  if (chosen == null || chosen.isEmpty) return;
  for (final id in chosen) {
    await data.transactions.validate(id);
  }
  if (context.mounted) {
    showKibuoToast(context, l.draftsValidated(chosen.length));
  }
}

class _DraftsPicker extends StatefulWidget {
  const _DraftsPicker({required this.data, required this.rows});

  final EntryData data;
  final List<(TransactionInfo, OperationLabels, String?)> rows;

  @override
  State<_DraftsPicker> createState() => _DraftsPickerState();
}

class _DraftsPickerState extends State<_DraftsPicker> {
  late final _on = {
    for (final (t, _, why) in widget.rows)
      if (why == null) t.id,
  };

  Future<void> _open(TransactionInfo t) async {
    final navigator = Navigator.of(context);
    await openDraft(context, widget.data, t);
    // Changed on its card: the sheet's list no longer holds.
    final now = await widget.data.transactions.get(t.id);
    if (now == null || !now.isDraft) navigator.pop(const <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final one = widget.rows.length == 1;
    final n = _on.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelpText(l.draftsSheetHelp),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.fromLTRB(one ? 14 : 4, 4, 14, 4),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: Column(
            children: [
              for (final (i, (t, labels, why)) in widget.rows.indexed) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: KibuoColors.background,
                  ),
                _DraftLine(
                  t: t,
                  labels: labels,
                  why: why,
                  check: one ? null : _on.contains(t.id),
                  onCheck: why != null
                      ? null
                      : () => setState(
                          () => _on.contains(t.id)
                              ? _on.remove(t.id)
                              : _on.add(t.id),
                        ),
                  onOpen: () => _open(t),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        KibuoButton(
          label: one ? l.draftsSheetValidateOne : l.draftsSheetValidate(n),
          onPressed: n == 0 ? null : () => Navigator.of(context).pop([..._on]),
        ),
        const SizedBox(height: 8),
        KibuoButton(
          label: l.draftsSheetLater,
          kind: ButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _DraftLine extends StatelessWidget {
  const _DraftLine({
    required this.t,
    required this.labels,
    required this.why,
    required this.check,
    required this.onCheck,
    required this.onOpen,
  });

  final TransactionInfo t;
  final OperationLabels labels;
  final String? why;

  /// Null with a single draft: no box.
  final bool? check;
  final VoidCallback? onCheck;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final check = this.check;
    final kind = switch (t.kind) {
      EntryKind.expense => l.entryExpense,
      EntryKind.income => l.entryIncome,
      EntryKind.transfer => l.transferKind,
    };
    final day = dayLabel(context, t.date.toLocal()).toLowerCase();
    TextStyle bold(TextStyle s) => s.copyWith(
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(700)],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Row(
        children: [
          if (check != null)
            SizedBox.square(
              dimension: KibuoTheme.heightTouch,
              child: Semantics(
                checked: check,
                child: InkWell(
                  onTap: onCheck,
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: check ? KibuoColors.accent : KibuoColors.surface,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: check
                              ? KibuoColors.accent
                              : KibuoColors.lineStrong,
                          width: 2,
                        ),
                      ),
                      child: check
                          ? const Icon(
                              KibuoIcons.checkBold,
                              size: 14,
                              color: KibuoColors.surface,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          if (check != null) const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Opacity(
                opacity: check == false ? 0.5 : 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 60),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draftName(t, labels),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bold(KibuoType.rowLabel),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              why ??
                                  l.draftsSheetLine(kind, day, labels.account),
                              maxLines: 2,
                              style: KibuoType.caption.copyWith(
                                color: why == null
                                    ? KibuoColors.inkSecondary
                                    : KibuoColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        signedTotal(context, t),
                        style: bold(KibuoType.rowLabel)
                            .copyWith(color: kindColors(t.kind).ink),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        KibuoIcons.caretRight,
                        size: 18,
                        color: KibuoColors.lineStrong,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
