import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/amount_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/confirm_sheet.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/hatched_bar.dart';
import 'package:kibuo/ui/kit/scrolling_line.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/kit/value_row.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/obligations/debts_screen.dart' show debtWord;
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';

String _lang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String _money(BuildContext context, Money m) =>
    formatMoney(m, currencyOf(m.currency), _lang(context));

String _upper(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

String _lower(String t) => t.isEmpty ? t : t[0].toLowerCase() + t.substring(1);

/// A debt's card (canvas FicheDette): the name and « Modifier », what is
/// left in large, the bar of what is paid back, the due date, the
/// repayments (each opens its operation), then « Rembourser ». Its
/// reminder comes with the debts' reminders.
class DebtScreen extends StatefulWidget {
  const DebtScreen({
    super.key,
    required this.data,
    required this.debts,
    required this.id,
    this.now = DateTime.now,
  });

  final EntryData data;
  final DebtRepository debts;
  final String id;
  final DateTime Function() now;

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  DebtDetail? _detail;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await widget.debts.detail(widget.id);
    if (!mounted) return;
    if (detail == null) {
      setState(() => _gone = true);
      return;
    }
    setState(() => _detail = detail);
  }

  Future<void> _repay() async {
    final detail = _detail;
    if (detail == null) return;
    await repayDebt(
      context,
      data: widget.data,
      debts: widget.debts,
      detail: detail,
      now: widget.now,
      offerDebt: false,
      onSaved: _load,
    );
    await _load();
  }

  Future<void> _edit() async {
    final detail = _detail;
    if (detail == null) return;
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EditDebtScreen(debts: widget.debts, detail: detail),
      ),
    );
    if (!mounted) return;
    if (deleted == true) {
      Navigator.of(context).pop();
      return;
    }
    await _load();
  }

  Future<void> _forgive() async {
    final detail = _detail;
    if (detail == null) return;
    final l = AppLocalizations.of(context);
    final d = detail.line;
    final left = _money(context, d.left);
    final sure = await confirmRemoval(
      context,
      title: l.debtForgive,
      summary: Row(
        children: [
          Expanded(child: Text(d.person, style: KibuoType.itemName)),
          Text(left, style: KibuoType.cardTitle),
        ],
      ),
      text: l.debtForgiveText(left),
      action: l.debtForgive,
    );
    if (!sure || !mounted) return;
    final now = widget.now();
    await widget.debts.settleWithoutPayment(
      d.id,
      on: now,
      note: l.debtForgivenNote(
        DateFormat.MMMMd(_lang(context)).format(now),
        left,
      ),
    );
    await _load();
  }

  Future<void> _openRepayment(Repayment r) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OperationDetailScreen(data: widget.data, id: r.id),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final detail = _detail;
    if (_gone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
    if (detail == null) return const Scaffold(body: SizedBox.shrink());
    final d = detail.line;
    final owe = d.direction == DebtDirection.owe;
    final paid = Money(d.amount.minor - d.left.minor, d.amount.currency);
    final due = d.due;
    final now = widget.now();
    final dueText = due == null
        ? l.debtsNoDue
        : '${_upper(DateFormat.MMMMEEEEd(_lang(context)).format(due))} · '
              '${_lower(debtWord(l, d, now))}';
    // Too long: « Mer. 25 nov. · après-demain » (owner, 23 November).
    final dueShort = due == null
        ? dueText
        : '${_upper(DateFormat.MMMEd(_lang(context)).format(due))} · '
              '${_lower(debtWord(l, d, now))}';
    return Scaffold(
      appBar: AppBar(
        title: Text(d.person),
        actions: [
          TextButton(
            onPressed: _edit,
            child: Text(
              l.debtEditAction,
              style: KibuoType.buttonSmall.copyWith(color: KibuoColors.accent),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  owe ? l.debtLeftOwe : l.debtLeftOwed,
                  style: KibuoType.body.copyWith(
                    color: KibuoColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _money(context, d.left),
                  style: KibuoType.bigAmount.copyWith(
                    fontSize: 38,
                    height: 44 / 38,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.repaidShare,
                    minHeight: 8,
                    color: KibuoColors.accent,
                    backgroundColor: KibuoColors.accentTintOpen,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        owe
                            ? l.debtRepaidOf(
                                _money(context, paid),
                                _money(context, d.amount),
                              )
                            : l.debtReceivedOf(
                                _money(context, paid),
                                _money(context, d.amount),
                              ),
                        style: KibuoType.body.copyWith(
                          fontSize: 13,
                          color: KibuoColors.inkSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${(d.repaidShare * 100).round()} %',
                      style: KibuoType.body.copyWith(
                        fontSize: 13,
                        color: KibuoColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                if (d.forgivenSettled && d.settledOn != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.debtForgivenOn(
                      DateFormat.MMMMd(_lang(context)).format(d.settledOn!),
                      _money(context, d.forgiven!),
                    ),
                    style: KibuoType.body
                        .copyWith(fontSize: 13, color: KibuoColors.accent)
                        .weight(600),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: KibuoColors.background),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      l.debtDue,
                      style: KibuoType.body.copyWith(
                        color: KibuoColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FittingLine(
                        full: dueText,
                        short: dueShort,
                        style: KibuoType.body.weight(600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Its own reminder, as for a recurrence (PRODUCT); none without a
          // due date or once settled.
          if (!d.settled && due != null && widget.data.reminders != null) ...[
            const SizedBox(height: 12),
            SettingsCard(
              children: [
                RuleReminderField(store: widget.data.reminders!, ruleId: d.id),
              ],
            ),
          ],
          const SizedBox(height: GroupTitle.before),
          GroupTitle(
            title: l.debtRepayments,
            trailing: detail.repayments.isEmpty
                ? null
                : GroupNote(l.debtRepaymentsCount(detail.repayments.length)),
          ),
          if (detail.repayments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: HelpText(
                d.forgivenSettled
                    ? l.debtNoRepaymentForgiven
                    : l.debtNoRepayment,
              ),
            )
          else
            SettingsCard(
              children: [
                for (final r in detail.repayments)
                  InkWell(
                    onTap: () => _openRepayment(r),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _upper(
                                    DateFormat.MMMMEEEEd(_lang(context))
                                        .format(r.date),
                                  ),
                                  style: KibuoType.rowLabel,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.account,
                                  style: KibuoType.body.copyWith(
                                    fontSize: 13,
                                    color: KibuoColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(context, r.amount),
                            style: KibuoType.rowLabel.weight(600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          // Given up: what is left goes, nothing moves (PRODUCT).
          if (!d.settled)
            ActionUnderCard(label: l.debtForgive, onPressed: _forgive),
        ],
      ),
      bottomNavigationBar: d.settled
          ? null
          : BottomAction(
              child: KibuoButton(
                label: owe ? l.debtRepay : l.debtCollect,
                onPressed: _repay,
              ),
            ),
    );
  }
}

/// « Rembourser Patrick » (canvas RembourserV3): the debt's bar with the
/// part being paid hatched, then Montant (what is left, never more),
/// Depuis or Vers (an account), Date, the rate when the account's currency
/// differs; « Rembourser » or « Plus tard ». True once saved.
Future<bool> repayDebt(
  BuildContext context, {
  required EntryData data,
  required DebtRepository debts,
  required DebtDetail detail,
  DateTime Function() now = DateTime.now,
  bool offerDebt = true,
  VoidCallback? onSaved,
}) async {
  final accounts = await data.accounts.accounts();
  if (!context.mounted) return false;
  final l = AppLocalizations.of(context);
  final owe = detail.line.direction == DebtDirection.owe;
  var current = detail;
  _Repaid? start;
  var saved = false;
  while (true) {
    if (!context.mounted) return saved;
    final done = await showKibuoSheet<_Repaid>(
      context,
      title: owe
          ? l.debtRepayTitle(detail.line.person)
          : l.debtCollectTitle(detail.line.person),
      builder: (_) => _RepaySheet(
        data: data,
        debts: debts,
        detail: current,
        accounts: accounts,
        now: now,
        start: start,
      ),
    );
    if (done == null || !context.mounted) return saved;
    saved = true;
    // What lies behind updates at once, under the confirmation.
    onSaved?.call();
    final after = await debts.detail(detail.line.id);
    if (after == null || !context.mounted) return saved;
    // « Remboursement enregistré » (canvas ConfirmA): what was paid, what
    // is left, « Annuler et modifier » and « Voir la dette ».
    final choice = await _confirmRepaid(
      context,
      after: after,
      done: done,
      accounts: accounts,
      now: now(),
      offerDebt: offerDebt,
    );
    if (!context.mounted) return saved;
    switch (choice) {
      case _AfterRepay.edit:
        // Undone, then the same sheet again, as it was.
        await data.transactions.delete(done.id);
        onSaved?.call();
        final back = await debts.detail(detail.line.id);
        if (back == null) return saved;
        current = back;
        start = done;
        continue;
      case _AfterRepay.see:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => DebtScreen(
              data: data,
              debts: debts,
              id: detail.line.id,
              now: now,
            ),
          ),
        );
      case null:
        break;
    }
    return saved;
  }
}

/// What the sheet saved, to show it and, if asked, to start again from it.
class _Repaid {
  const _Repaid({
    required this.id,
    required this.amount,
    required this.accountId,
    required this.date,
  });

  final String id;
  final Money amount;
  final String accountId;
  final DateTime date;
}

enum _AfterRepay { edit, see }

Future<_AfterRepay?> _confirmRepaid(
  BuildContext context, {
  required DebtDetail after,
  required _Repaid done,
  required List<AccountInfo> accounts,
  required DateTime now,
  required bool offerDebt,
}) {
  final l = AppLocalizations.of(context);
  final d = after.line;
  final owe = d.direction == DebtDirection.owe;
  final account =
      accounts.where((a) => a.id == done.accountId).firstOrNull?.name ?? '';
  return showConfirmSheet<_AfterRepay>(
    context,
    title: d.settled
        ? (owe ? l.debtSettledOweToast : l.debtSettledOwedToast)
        : (owe ? l.debtRepaySaved : l.debtCollectSaved),
    card: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SavedLine(
          title: debtTitle(l, owe ? 'debtOut' : 'receivableIn', d.person),
          subtitle: '$account · ${operationWhen(context, done.date, now)}',
          amount: '${owe ? '−' : '+'}${_money(context, done.amount)}',
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: d.repaidShare,
            minHeight: 8,
            color: KibuoColors.accent,
            backgroundColor: KibuoColors.accentTintOpen,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                l.debtLeftOf(
                  _money(context, d.left),
                  _money(context, d.amount),
                ),
                style: KibuoType.caption,
              ),
            ),
            Text(
              '${(d.repaidShare * 100).round()} %',
              style: KibuoType.caption,
            ),
          ],
        ),
      ],
    ),
    actions: [
      ConfirmAction(l.entryUndoEdit, _AfterRepay.edit),
      if (offerDebt) ConfirmAction(l.debtSeeDebt, _AfterRepay.see, main: true),
    ],
  );
}

class _RepaySheet extends StatefulWidget {
  const _RepaySheet({
    required this.data,
    required this.debts,
    required this.detail,
    required this.accounts,
    required this.now,
    this.start,
  });

  final EntryData data;
  final DebtRepository debts;
  final DebtDetail detail;
  final List<AccountInfo> accounts;
  final DateTime Function() now;

  /// A repayment undone to be changed: the sheet starts from it.
  final _Repaid? start;

  @override
  State<_RepaySheet> createState() => _RepaySheetState();
}

class _RepaySheetState extends State<_RepaySheet> {
  late Money _amount = widget.start?.amount ?? widget.detail.line.left;
  late AccountInfo? _account =
      widget.accounts
          .where(
            (a) =>
                a.id ==
                (widget.start?.accountId ?? widget.detail.openingAccountId),
          )
          .firstOrNull ??
      widget.accounts.firstOrNull;
  late DateTime _date = widget.start?.date ?? widget.now();
  ExchangeRate? _today;
  bool _rateTyped = false;
  String _rateText = '';
  bool _saving = false;

  DebtLine get _line => widget.detail.line;

  bool get _owe => _line.direction == DebtDirection.owe;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  bool get _converts =>
      _account != null && _account!.currency != _line.amount.currency;

  (String, String) get _rateWay => rateDirection(
    main: currencyOf(_account!.currency),
    other: currencyOf(_line.amount.currency),
  );

  ExchangeRate? get _rate {
    if (!_converts) return null;
    if (!_rateTyped) return _today;
    final value = RateValue.tryParse(_rateText);
    if (value == null) return null;
    final (base, quote) = _rateWay;
    return ExchangeRate(base: base, quote: quote, value: value);
  }

  Future<void> _loadRate() async {
    if (!_converts) return;
    final (base, quote) = _rateWay;
    final info = await widget.data.currencies.latestRate(
      _account!.currency,
      _line.amount.currency,
    );
    if (!mounted) return;
    setState(() {
      _today = info?.rate.toward(base, quote);
      _rateTyped = _today == null;
      _rateText = '';
    });
  }

  Future<void> _pickAmount() async {
    final l = AppLocalizations.of(context);
    final picked = await typeAmount(
      context,
      title: l.entryAmount,
      start: _amount,
      most: _line.left,
      cap: l.debtLeftCap,
    );
    if (picked != null) setState(() => _amount = picked);
  }

  Future<void> _pickAccount() async {
    final picked = await pickAccount(
      context,
      accounts: widget.accounts,
      current: _account?.id,
    );
    if (picked == null) return;
    setState(() => _account = picked);
    await _loadRate();
  }

  Future<void> _pickDate() async {
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        // Today keeps its time, like any operation; another day, midnight.
        final today =
            picked.year == now.year &&
            picked.month == now.month &&
            picked.day == now.day;
        _date = today ? now : picked;
      });
    }
  }

  Future<void> _pickRate() async {
    final (base, quote) = _rateWay;
    final choice = await pickEntryRate(
      context,
      income: !_owe,
      paid: _money(context, _amount),
      base: base,
      quote: quote,
      today: _today,
      current: RateChoice(typed: _rateTyped, value: _rateText),
    );
    if (choice != null) {
      setState(() {
        _rateTyped = choice.typed;
        _rateText = choice.value ?? '';
      });
    }
  }

  bool get _ready =>
      _account != null && _amount.minor > 0 && (!_converts || _rate != null);

  Future<void> _save() async {
    if (!_ready || _saving) return;
    setState(() => _saving = true);
    final id = await widget.debts.repay(
      _line.id,
      amount: _amount,
      accountId: _account!.id,
      date: _date,
      rate: _rate,
      rateTyped: _rateTyped,
    );
    if (mounted) {
      Navigator.of(context).pop(
        _Repaid(id: id, amount: _amount, accountId: _account!.id, date: _date),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = _lang(context);
    final ink = _owe ? KibuoColors.debtInk : KibuoColors.accent;
    final track = _owe ? KibuoColors.debtTint : KibuoColors.accentTintStrong;
    final hatch = _owe ? KibuoColors.debtLine : KibuoColors.accentDash;
    final total = _line.amount.minor;
    final paid = total - _line.left.minor;
    final after = total <= 0 ? 1.0 : (paid + _amount.minor) / total;
    final (state, _) = debtState(_line, widget.now());
    final now = widget.now();
    final today =
        _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: _line.person,
                        children: [
                          TextSpan(
                            text:
                                ' · ${_owe ? l.debtBorrowedOn(DateFormat.MMMd(lang).format(widget.detail.openedOn)) : l.debtLentOn(DateFormat.MMMd(lang).format(widget.detail.openedOn))}',
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.body.weight(700),
                    ),
                  ),
                  if (state == DebtState.late)
                    Text(
                      debtWord(l, _line, now),
                      style: KibuoType.caption
                          .copyWith(color: KibuoColors.danger)
                          .weight(600),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              HatchedBar(
                done: total <= 0 ? 1 : paid / total,
                after: after.clamp(0, 1),
                ink: ink,
                track: track,
                hatch: hatch,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _owe
                          ? l.debtRepaidOf(
                              _money(
                                context,
                                Money(paid, _line.amount.currency),
                              ),
                              _money(context, _line.amount),
                            )
                          : l.debtReceivedOf(
                              _money(
                                context,
                                Money(paid, _line.amount.currency),
                              ),
                              _money(context, _line.amount),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.caption,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: '+${_money(context, _amount)}',
                      style: TextStyle(color: ink).weight(700),
                      children: [
                        TextSpan(text: ' · ${(after * 100).round()} %'),
                      ],
                    ),
                    style: KibuoType.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SettingsCard(
          children: [
            ValueRow(
              label: l.entryAmount,
              value: _money(context, _amount),
              onTap: _pickAmount,
              color: ink,
            ),
            ValueRow(
              label: _owe ? l.debtFrom : l.debtTo,
              value: _account?.name ?? l.entryNoAccount,
              onTap: _pickAccount,
            ),
            ValueRow(
              label: l.entryDate,
              value: today
                  ? l.entryToday
                  : _upper(DateFormat.MMMd(lang).format(_date)),
              onTap: _pickDate,
            ),
            if (_converts)
              ValueRow(
                label: l.entryRateTitle,
                value: _rate == null ? '' : formatRate(_rate!, lang),
                onTap: _pickRate,
              ),
          ],
        ),
        const SizedBox(height: 12),
        KibuoButton(
          label: _owe ? l.debtRepay : l.debtCollect,
          onPressed: _ready && !_saving ? _save : null,
        ),
        const SizedBox(height: 8),
        KibuoButton(
          label: l.debtLater,
          kind: ButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// « Modifier la dette »: the name, the amount (never below what was paid
/// back) and the due date; « Supprimer la dette » at the bottom. Pops
/// true when the debt was deleted.
class EditDebtScreen extends StatefulWidget {
  const EditDebtScreen({super.key, required this.debts, required this.detail});

  final DebtRepository debts;
  final DebtDetail detail;

  @override
  State<EditDebtScreen> createState() => _EditDebtScreenState();
}

class _EditDebtScreenState extends State<EditDebtScreen> {
  DebtLine get _line => widget.detail.line;
  late final _name = TextEditingController(text: _line.person);
  late Money _amount = _line.amount;
  late DateTime? _due = _line.due;
  bool _saving = false;

  bool get _owe => _line.direction == DebtDirection.owe;

  Money get _repaid =>
      Money(_line.amount.minor - _line.left.minor, _line.amount.currency);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAmount() async {
    FocusScope.of(context).unfocus();
    // No ceiling: the floor is checked below.
    final picked = await typeAmount(
      context,
      title: AppLocalizations.of(context).entryAmount,
      start: _amount,
    );
    if (picked != null) setState(() => _amount = picked);
  }

  Future<void> _pickDue() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime(now.year, now.month, now.day + 7),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) {
      setState(() => _due = DateTime(picked.year, picked.month, picked.day));
    }
  }

  bool get _ready =>
      _name.text.trim().isNotEmpty && _amount.minor >= _repaid.minor;

  Future<void> _save() async {
    if (!_ready || _saving) return;
    setState(() => _saving = true);
    await widget.debts.edit(
      _line.id,
      person: _name.text,
      amount: _amount,
      due: _due,
    );
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final sure = await confirmRemoval(
      context,
      title: _owe ? l.debtDeleteOwe : l.debtDeleteOwed,
      summary: Row(
        children: [
          Expanded(child: Text(_line.person, style: KibuoType.itemName)),
          Text(_money(context, _line.left), style: KibuoType.cardTitle),
        ],
      ),
      text: l.debtDeleteText(widget.detail.operations),
      action: _owe ? l.debtDeleteOwe : l.debtDeleteOwed,
    );
    if (!sure) return;
    await widget.debts.delete(_line.id);
    if (!mounted) return;
    showKibuoToast(context, l.debtDeleted(_line.person));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = _lang(context);
    final below = _amount.minor < _repaid.minor;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(
              title: _owe ? l.debtEditTitleOwe : l.debtEditTitleOwed,
              cancel: l.cancel,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  KibuoTextField(
                    label: _owe ? l.debtPersonOwe : l.debtPersonOwed,
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    error: _name.text.trim().isEmpty
                        ? l.debtPersonMissing
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ValueField(
                    label: l.entryAmount,
                    value: shownTyped(
                      context,
                      typedFrom(_amount, currencyOf(_amount.currency)),
                    ),
                    unit: _amount.currency,
                    focused: false,
                    onTap: _pickAmount,
                    error: below
                        ? l.debtAmountMin(_money(context, _repaid))
                        : null,
                    note: below || _repaid.minor == 0
                        ? null
                        : l.debtAmountMin(_money(context, _repaid)),
                  ),
                  const SizedBox(height: 16),
                  FieldLabel(l.debtDue),
                  DateField(
                    text: _due == null
                        ? l.debtsNoDue
                        : _upper(DateFormat.yMMMMd(lang).format(_due!)),
                    onTap: _pickDue,
                  ),
                  if (_due != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextAction(
                        label: l.debtDueClear,
                        onPressed: () => setState(() => _due = null),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SettingsCard(
                    children: [
                      SettingsRow(
                        label: _owe ? l.debtDeleteOwe : l.debtDeleteOwed,
                        danger: true,
                        onTap: _delete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 24,
              ),
              child: KibuoButton(
                label: l.entrySave,
                onPressed: _ready && !_saving ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [full] when it fits, else [short]; when even that is cut, it slides to
/// its end and back, three times, then rests at its start (owner, 23
/// November).
class _FittingLine extends StatelessWidget {
  const _FittingLine({
    required this.full,
    required this.short,
    required this.style,
  });

  final String full;
  final String short;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final drawn = DefaultTextStyle.of(context).style.merge(style);
      bool fits(String text) =>
          (TextPainter(
            text: TextSpan(text: text, style: drawn),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout()).width <=
          box.maxWidth;
      if (fits(full)) {
        return Text(full, textAlign: TextAlign.right, style: style);
      }
      if (fits(short)) {
        return Text(short, textAlign: TextAlign.right, style: style);
      }
      return ScrollingLine(short, style: style, runs: 3);
    },
  );
}
