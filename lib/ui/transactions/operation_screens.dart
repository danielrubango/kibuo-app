import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_form_screen.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/attachments_card.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/overdraft_check.dart';

/// The detail of an operation (canvas OperationDetailBas): the category,
/// the amount and the frozen rate, the fields, the note, « Dupliquer »;
/// « Modifier » at the top.
class OperationDetailScreen extends StatefulWidget {
  const OperationDetailScreen({
    super.key,
    required this.data,
    required this.id,
  });

  final EntryData data;
  final String id;

  @override
  State<OperationDetailScreen> createState() => _OperationDetailScreenState();
}

class _OperationDetailScreenState extends State<OperationDetailScreen> {
  TransactionInfo? _t;
  OperationLabels? _labels;
  bool _noteOpen = false;
  List<AttachmentInfo> _attachments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await widget.data.transactions.get(widget.id);
    if (!mounted) return;
    if (t == null) {
      // Gone (deleted elsewhere): back to the list.
      Navigator.of(context).pop();
      return;
    }
    final labels = await OperationLabels.of(context, widget.data, t);
    final attachments = await widget.data.attachments.list(t.id);
    if (mounted) {
      setState(() {
        _t = t;
        _labels = labels;
        _attachments = attachments;
      });
    }
  }

  Future<void> _edit() async {
    await runEntry(
      context,
      widget.data,
      kind: _t!.kind,
      initial: _t,
      editing: true,
    );
    await _load();
  }

  /// « Supprimer cette dépense ? » (canvas DelConfirm): the operation as
  /// saved, what deleting does to its account, then « Supprimer ».
  Future<void> _confirmDelete() async {
    final saved = _t!;
    final lang = Localizations.localeOf(context).languageCode;
    final l = AppLocalizations.of(context);
    final labels = await OperationLabels.of(context, widget.data, saved);
    // Deleting an income (or what a transfer brought) may take its account
    // below its floor (PRODUCT: Découvert).
    final refusal = checkOverdraft(
      accounts: await widget.data.accounts.accounts(),
      before: effectsOf(saved),
      beforeDate: saved.date,
      after: const {},
      date: saved.date,
    );
    if (!mounted) return;
    final amount = formatMoney(
      saved.total.total,
      currencyOf(saved.total.total.currency),
      lang,
    );
    final choice = await showKibuoSheet<_DeleteChoice>(
      context,
      title: switch (saved.kind) {
        EntryKind.expense => l.entryDeleteExpenseTitle,
        EntryKind.income => l.entryDeleteIncomeTitle,
        EntryKind.transfer => l.entryDeleteTransferTitle,
      },
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
            ),
            child: Row(
              children: [
                OperationTile(kind: saved.kind, labels: labels, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels.categoryPath.split(' › ').last,
                        style: KibuoType.rowLabel.copyWith(
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation.weight(600)],
                        ),
                      ),
                      Text(
                        '${labels.account} · '
                        '${operationWhen(context, saved.date, DateTime.now())}',
                        style: KibuoType.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  signedTotal(context, saved),
                  style: KibuoType.itemName.copyWith(
                    color: kindColors(saved.kind).ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (refusal != null) ...[
            // Canvas DecouvertSuppressionA: one red line, then the way out.
            Row(
              children: [
                const Icon(
                  KibuoIcons.warning,
                  size: 18,
                  color: KibuoColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.overdraftWouldGo(
                      refusal.account.name,
                      formatMoney(
                        refusal.after,
                        currencyOf(refusal.after.currency),
                        lang,
                      ),
                    ),
                    style: KibuoType.body.copyWith(
                      fontSize: 14,
                      color: KibuoColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Material(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
              child: InkWell(
                borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
                onTap: () => Navigator.of(context).pop(_DeleteChoice.authorize),
                child: SizedBox(
                  height: KibuoTheme.heightSecondary,
                  child: Center(
                    child: Text(
                      l.overdraftAllow,
                      style: KibuoType.buttonSmall.copyWith(
                        color: KibuoColors.accent,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(switch (saved.kind) {
              EntryKind.expense => l.entryDeleteExpenseHelp(
                labels.account,
                amount,
              ),
              EntryKind.income => l.entryDeleteIncomeHelp(
                labels.account,
                amount,
              ),
              EntryKind.transfer => l.entryDeleteTransferHelp(
                labels.account,
                amount,
                labels.toAccount ?? '',
                formatMoney(
                  saved.arrived!,
                  currencyOf(saved.arrived!.currency),
                  lang,
                ),
              ),
            }, style: KibuoType.help),
            const SizedBox(height: 16),
            KibuoButton(
              label: l.entryDeleteConfirm,
              kind: ButtonKind.danger,
              onPressed: () => Navigator.of(context).pop(_DeleteChoice.delete),
            ),
          ],
        ],
      ),
    );
    switch (choice) {
      case _DeleteChoice.delete:
        if (!mounted ||
            !await confirmWithCode(context, l.protectDeleteOperation)) {
          return;
        }
        await widget.data.transactions.delete(saved.id);
        if (mounted) Navigator.of(context).pop();
      case _DeleteChoice.authorize:
        if (!mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AccountFormScreen(
              accounts: widget.data.accounts,
              currencies: widget.data.currencies,
              account: refusal!.account,
              categories: widget.data.categories,
              transactions: widget.data.transactions,
            ),
          ),
        );
      case null:
        return;
    }
  }

  Future<void> _duplicate() async {
    await runEntry(context, widget.data, kind: _t!.kind, initial: _t);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final t = _t;
    final labels = _labels;
    if (t == null || labels == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final expense = t.kind == EntryKind.expense;
    final transfer = t.kind == EntryKind.transfer;
    final (:tint, :edge, :ink) = kindColors(t.kind);
    String money(Money m) => formatMoney(m, currencyOf(m.currency), lang);
    final date = t.date.toLocal();
    final dateText = DateFormat.yMMMMEEEEd(lang).format(date);
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextAction(label: l.currenciesEdit, onPressed: _edit),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
              border: Border.all(color: edge, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OperationTile(kind: t.kind, labels: labels, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labels.categoryPath.split(' › ').last,
                            style: KibuoType.cardTitle,
                          ),
                          Text(switch (t.kind) {
                            EntryKind.expense => l.entryExpense,
                            EntryKind.income => l.entryIncome,
                            EntryKind.transfer => l.transferKind,
                          }, style: KibuoType.caption.copyWith(color: ink)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(signedTotal(context, t), style: KibuoType.bigAmount),
                // « Depuis M-Pesa → Vers Épargne » (canvas
                // OperationCarteTransfert).
                if (transfer) ...[
                  const SizedBox(height: 12),
                  _TransferRoute(
                    from: labels.account,
                    to: labels.toAccount ?? '',
                    background: edge.withValues(alpha: 0.35),
                    l: l,
                  ),
                ],
                if (t.rate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: edge,
                      borderRadius: BorderRadius.circular(
                        KibuoTheme.radiusPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(KibuoIcons.lockSimple, size: 14),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            transfer
                                ? l.transferArrivedChip(
                                    money(t.arrived!),
                                    formatRate(t.rate!, lang),
                                  )
                                : (expense
                                      ? l.entryPaidChip
                                      : l.entryReceivedChip)(
                                    money(t.paid),
                                    formatRate(t.rate!, lang),
                                  ),
                            style: KibuoType.caption.copyWith(
                              color: KibuoColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // A transfer's accounts are in its card.
                if (!transfer) ...[
                  EntryField(
                    icon: KibuoIcons.wallet,
                    label: l.entryAccount,
                    value: labels.account,
                    trailing: labels.accountCurrency,
                  ),
                  EntryField(
                    icon: KibuoIcons.tag,
                    label: l.entryCategory,
                    value: labels.categoryPath,
                  ),
                ],
                EntryField(
                  icon: KibuoIcons.calendarBlank,
                  label: l.entryDate,
                  value: dateText[0].toUpperCase() + dateText.substring(1),
                  trailing: DateFormat.Hm(lang).format(date),
                ),
                if (t.total.fees.minor > 0)
                  EntryField(
                    icon: KibuoIcons.receipt,
                    label: l.entryFees,
                    value: formatMoney(
                      t.total.fees,
                      currencyOf(t.total.fees.currency),
                      lang,
                    ),
                  ),
              ],
            ),
          ),
          // Only looked at here; added and removed from « Modifier »
          // (owner, 15 November 2026).
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            AttachmentsCard(
              items: _attachments,
              preview: widget.data.attachments.read,
              onOpen: (a) => viewAttachment(context, widget.data, a),
            ),
          ],
          if (t.note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.entryNote, style: KibuoType.caption),
                  const SizedBox(height: 4),
                  Text(
                    t.note!,
                    maxLines: _noteOpen ? null : 3,
                    overflow: _noteOpen ? null : TextOverflow.ellipsis,
                    style: KibuoType.body.copyWith(fontSize: 15),
                  ),
                  if (!_noteOpen && t.note!.length > 120)
                    TextAction(
                      label: l.entryReadNote,
                      onPressed: () => setState(() => _noteOpen = true),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          KibuoButton(
            label: l.entryDuplicate,
            kind: ButtonKind.secondary,
            icon: KibuoIcons.copy,
            onPressed: _duplicate,
          ),
          // Under « Dupliquer », as a plain red action (owner, 15 November
          // 2026; canvas OperationCarteTransfert).
          const SizedBox(height: 8),
          Center(
            child: TextAction(
              label: l.entryDeleteOperation,
              color: KibuoColors.danger,
              onPressed: _confirmDelete,
            ),
          ),
        ],
      ),
    );
  }
}

/// « Depuis M-Pesa → Vers Épargne », in a band of the card.
class _TransferRoute extends StatelessWidget {
  const _TransferRoute({
    required this.from,
    required this.to,
    required this.background,
    required this.l,
  });

  final String from;
  final String to;
  final Color background;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    Widget side(String label, String name) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: KibuoType.caption.copyWith(color: KibuoColors.projectInk),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KibuoType.body.copyWith(
              fontWeight: FontWeight.w600,
              fontVariations: const [FontVariation.weight(600)],
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      ),
      child: Row(
        children: [
          side(l.transferDepuis, from),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              KibuoIcons.arrowRight,
              size: 16,
              color: KibuoColors.projectInk,
            ),
          ),
          side(l.transferTo, to),
        ],
      ),
    );
  }
}

enum _DeleteChoice { delete, authorize }
