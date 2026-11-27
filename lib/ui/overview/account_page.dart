import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/worth.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/kit/day_header.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/overview/enlarged_parts.dart';
import 'package:kibuo/ui/overview/overview_labels.dart';
import 'package:kibuo/ui/overview/share_row.dart';
import 'package:kibuo/ui/overview/worth_tab.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';
import 'package:kibuo/ui/transactions/overdraft_check.dart';

/// An account over the Aperçu's period (variant B, canvas CompteB, 27
/// November 2026): its balance in big, what it gained or lost, its curve,
/// what came in and went out, then its operations day by day. Amounts are
/// in the account's own currency, as in Comptes.
class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.data,
    required this.accountId,
    required this.name,
    required this.periodLabel,
    required this.kind,
    required this.offset,
    required this.span,
    required this.bars,
    required this.grouping,
    required this.startDay,
    required this.now,
  });

  final EntryData data;
  final String accountId;

  /// Shown at once, before the account is read.
  final String name;
  final String periodLabel;
  final PeriodKind kind;
  final int offset;
  final TimeSpan span;
  final List<TimeSpan> bars;
  final Grouping grouping;
  final int startDay;
  final DateTime now;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

typedef _Loaded = ({
  AccountInfo account,
  List<CustomAccountType> custom,

  /// What each operation did to the account, since its opening.
  List<WorthChange> moves,

  /// The period's operations, the latest first.
  List<(TransactionInfo, OperationLabels)> ops,
});

class _AccountPageState extends State<AccountPage> {
  _Loaded? _loaded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = widget.data.accounts;
    final account = [
      ...await accounts.accounts(),
      ...await accounts.accounts(archived: true),
    ].where((a) => a.id == widget.accountId).firstOrNull;
    if (account == null) return;
    final custom = await accounts.types();
    final moves = <WorthChange>[];
    final mine = <TransactionInfo>[];
    // As its balance does: what was saved from its opening on.
    for (final t in await widget.data.transactions.all()) {
      if (!t.counts || t.date.isBefore(account.openingDate)) continue;
      final change = effectsOf(t)[account.id];
      if (change == null) continue;
      final at = t.date.toLocal();
      moves.add((at: at, change: change));
      if (widget.span.contains(at)) mine.add(t);
    }
    mine.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    final ops = [
      for (final t in mine)
        (t, await OperationLabels.of(context, widget.data, t)),
    ];
    if (!mounted) return;
    setState(
      () =>
          _loaded = (account: account, custom: custom, moves: moves, ops: ops),
    );
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  String _money(int minor, String code, {bool signed = false}) {
    final text = formatMoney(Money(minor.abs(), code), currencyOf(code), _lang);
    if (!signed) return minor < 0 ? '−$text' : text;
    return minor == 0 ? text : '${minor < 0 ? '−' : '+'}$text';
  }

  Future<void> _open(TransactionInfo t) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OperationDetailScreen(data: widget.data, id: t.id),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loaded = _loaded;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(KibuoIcons.caretLeft, size: 22),
        ),
        title: Row(
          children: [
            if (loaded == null)
              const SizedBox(width: 36, height: 36)
            else
              PlainLineTile(
                icon: AccountTypeLabels(
                  l,
                  loaded.custom,
                ).icon(loaded.account.type),
                size: 36,
                color: KibuoColors.mint,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loaded?.account.name ?? widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.cardTitle.copyWith(fontSize: 18),
                  ),
                  Text(
                    widget.periodLabel,
                    style: KibuoType.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: loaded == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [_summary(l, loaded), ..._days(loaded)],
            ),
    );
  }

  /// The balance, its change, its curve, what came in and went out.
  Widget _summary(AppLocalizations l, _Loaded loaded) {
    final account = loaded.account;
    final code = account.currency;
    final now = widget.now;
    final running = widget.span.contains(now);
    final balance = account.balance.minor;
    final changes = [
      (at: account.openingDate.toLocal(), change: account.opening.minor),
      ...loaded.moves,
    ];
    final figure = worthAt(
      [running ? now : widget.span.end],
      current: balance,
      changes: changes,
    ).single;
    final change = worthChange(
      widget.span,
      current: balance,
      changes: changes,
      now: now,
    );
    // The curve: the period's start, then each bar's end (now for the bar
    // running).
    final begun = [
      for (final b in widget.bars)
        if (!b.start.isAfter(now)) b,
    ];
    final solid = worthAt(
      [
        widget.span.start,
        for (final b in begun) b.end.isAfter(now) ? now : b.end,
      ],
      current: balance,
      changes: changes,
    );
    final axis = curveAxis(
      l,
      _lang,
      widget.bars,
      widget.grouping,
      startDay: widget.startDay,
      today: running ? now : null,
    );
    // Today's date stands under its line, at the curve's last point.
    final at = running && widget.bars.isNotEmpty
        ? begun.length / widget.bars.length
        : widget.bars.length <= 1
        ? 0.0
        : (begun.length - 1) / (widget.bars.length - 1);
    final flows = flowsWithin(widget.span, loaded.moves);
    final when = worthWhen(
      l,
      _lang,
      widget.kind,
      widget.offset,
      widget.span,
      running: running,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(figure, code),
              style: KibuoType.bigAmount.copyWith(
                fontSize: 30,
                color: figure < 0 ? KibuoColors.danger : KibuoColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_money(change, code, signed: true)} $when',
            style: KibuoType.caption
                .copyWith(
                  fontSize: 13,
                  color: change < 0 ? KibuoColors.debtInk : KibuoColors.accent,
                )
                .copyWith(
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation.weight(700)],
                ),
          ),
          const SizedBox(height: 12),
          WorthCurve(
            solid: solid,
            ahead: const [],
            slots: widget.bars.length + 1,
            today: running,
          ),
          const SizedBox(height: 6),
          AxisLabels(axis, at: at, strong: running),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FlowBox(
                  label: l.overviewEntries,
                  value: _money(flows.entries, code, signed: true),
                  tint: KibuoColors.accentTint,
                  ink: KibuoColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FlowBox(
                  label: l.overviewExits,
                  value: _money(-flows.exits, code, signed: true),
                  tint: KibuoColors.debtTint,
                  ink: KibuoColors.debtInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The operations under their day, the latest day first. A transfer
  /// says whether it left the account or reached it.
  List<Widget> _days(_Loaded loaded) {
    final id = loaded.account.id;
    final days = <DateTime, List<(TransactionInfo, OperationLabels)>>{};
    for (final op in loaded.ops) {
      final d = op.$1.date.toLocal();
      (days[DateTime(d.year, d.month, d.day)] ??= []).add(op);
    }
    String Function(bool)? amount(TransactionInfo t) {
      if (t.kind != EntryKind.transfer) return null;
      final leaves = t.accountId == id;
      final m = leaves ? t.total.total : t.arrived ?? t.total.total;
      return (short) =>
          '${leaves ? '−' : '+'}'
          '${formatAmount(Money(m.minor.abs(), m.currency), currencyOf(m.currency), _lang, short: short)}';
    }

    return [
      for (final MapEntry(key: day, value: list) in days.entries) ...[
        const SizedBox(height: GroupTitle.before),
        GroupTitle(title: dayLabel(context, day)),
        for (final (i, (t, labels)) in list.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          OperationRow(
            t: t,
            labels: labels,
            title: (labels.categoryPath.split(' › ').last, null),
            subtitle: (
              '${labels.account} · '
                  '${DateFormat.Hm(_lang).format(t.date.toLocal())}',
              null,
            ),
            amount: amount(t),
            onTap: () => _open(t),
          ),
        ],
      ],
    ];
  }
}

/// « Entrées » or « Sorties » and its amount, on its tint.
class _FlowBox extends StatelessWidget {
  const _FlowBox({
    required this.label,
    required this.value,
    required this.tint,
    required this.ink,
  });

  final String label;
  final String value;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KibuoType.caption.copyWith(fontSize: 12)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: KibuoType.itemName.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
              color: ink,
            ),
          ),
        ),
      ],
    ),
  );
}
