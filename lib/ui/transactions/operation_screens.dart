import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// The Opérations tab until « Liste et recherche »: a simple list by day,
/// provisional (validated 15 November 2026). Touching a line opens it.
class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key, required this.data, this.refresh});

  final EntryData data;

  /// Bumped by the shell after a save, to reload.
  final Listenable? refresh;

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  List<(TransactionInfo, OperationLabels)> _list = const [];

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await widget.data.transactions.all();
    if (!mounted) return;
    final list = <(TransactionInfo, OperationLabels)>[];
    for (final t in all) {
      if (!mounted) return;
      list.add((t, await OperationLabels.of(context, widget.data, t)));
    }
    if (mounted) setState(() => _list = list);
  }

  Future<void> _open(TransactionInfo t) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OperationDetailScreen(data: widget.data, id: t.id),
      ),
    );
    await _load();
  }

  String _day(BuildContext context, DateTime date) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return l.entryToday;
    if (day == today.subtract(const Duration(days: 1))) return l.entryYesterday;
    final t = DateFormat.MMMMEEEEd(lang).format(local);
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    String? lastDay;
    final children = <Widget>[];
    for (final (t, labels) in _list) {
      final day = _day(context, t.date);
      if (day != lastDay) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(day, style: KibuoType.sectionTitle),
          ),
        );
        lastDay = day;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (labels.category != null)
                      CategoryTile(category: labels.category!, size: 36),
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
                            '${DateFormat.Hm(lang).format(t.date.toLocal())}',
                            style: KibuoType.caption,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      signedTotal(context, t),
                      style: KibuoType.cardTitle.copyWith(
                        color: t.kind == EntryKind.expense
                            ? KibuoColors.debtInk
                            : KibuoColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    // Placed like the other tabs' titles: 16 + 4 from the edge, 16 down.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(l.operationsTitle, style: KibuoType.tabTitle),
        ),
        if (_list.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Text(l.operationsEmpty, style: KibuoType.help),
          )
        else
          ...children,
      ],
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await widget.data.transactions.get(widget.id);
    if (!mounted) return;
    if (t == null) {
      // Deleted from « Modifier »: back to the list.
      Navigator.of(context).pop();
      return;
    }
    final labels = await OperationLabels.of(context, widget.data, t);
    if (mounted) {
      setState(() {
        _t = t;
        _labels = labels;
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
    final tint = expense ? KibuoColors.debtTint : KibuoColors.accentTint;
    final edge = expense
        ? const Color(0xFFF2CFB3)
        : KibuoColors.accentTintStrong;
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
                    if (labels.category != null)
                      CategoryTile(category: labels.category!, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labels.categoryPath.split(' › ').last,
                            style: KibuoType.cardTitle,
                          ),
                          Text(
                            expense ? l.entryExpense : l.entryIncome,
                            style: KibuoType.caption.copyWith(
                              color: expense
                                  ? KibuoColors.debtInk
                                  : KibuoColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(signedTotal(context, t), style: KibuoType.bigAmount),
                if (t.rate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
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
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            (expense ? l.entryPaidChip : l.entryReceivedChip)(
                              formatMoney(
                                t.paid,
                                currencyOf(t.paid.currency),
                                lang,
                              ),
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
          if (t.note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
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
                    const SizedBox(height: 10),
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
        ],
      ),
    );
  }
}
