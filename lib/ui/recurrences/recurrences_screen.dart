import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/empty_card.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/recurrences/rhythm_text.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// What the recurrence screens show of a rule: its names and icon.
class _Names {
  _Names(this.accounts, this.categories);

  final List<AccountInfo> accounts;
  final List<CategoryInfo> categories;

  static Future<_Names> load(EntryData data) async =>
      _Names(await data.accounts.accounts(), [
        for (final kind in CategoryKind.values)
          for (final c in await data.categories.categories(kind)) ...[
            c,
            ...c.subs,
          ],
      ]);

  CategoryInfo? category(String? id) =>
      categories.where((c) => c.id == id).firstOrNull;

  String account(String? id) =>
      accounts.where((a) => a.id == id).firstOrNull?.name ?? '';

  /// Its note, or its category, or where a transfer goes.
  String title(AppLocalizations l, RecurringInfo r) {
    if (r.note != null) return r.note!;
    final c = category(r.categoryId);
    if (c != null) return categoryName(l, c);
    return l.recurrenceToAccount(account(r.toAccountId));
  }
}

/// The rule's tile: its category's, or the transfer's arrows.
Widget _tile(RecurringInfo r, _Names names, double size) {
  final c = names.category(r.categoryId);
  if (r.kind == EntryKind.transfer || c == null) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KibuoColors.projectTint,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        KibuoIcons.arrowsLeftRight,
        size: size * 0.5,
        color: KibuoColors.projectInk,
      ),
    );
  }
  return CategoryTile(category: c, size: size);
}

String _signed(RecurringInfo r, String lang) {
  final text = formatMoney(r.amount, currencyOf(r.amount.currency), lang);
  return switch (r.kind) {
    EntryKind.expense => '−$text',
    EntryKind.income => '+$text',
    EntryKind.transfer => text,
  };
}

/// Opens « Nouvelle récurrence » or its « Modifier » (the entry, alone).
Future<bool> _openForm(
  BuildContext context,
  EntryData data, {
  RecurringInfo? rule,
}) async {
  final saved = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => EntryScreen(
        data: data,
        kind: rule?.kind ?? EntryKind.expense,
        ruleOnly: true,
        rule: rule,
        initial: rule == null
            ? null
            : TransactionInfo(
                id: rule.id,
                kind: rule.kind,
                accountId: rule.accountId,
                toAccountId: rule.toAccountId,
                categoryId: rule.categoryId,
                paid: rule.amount,
                total: EntryTotal(
                  kind: rule.kind,
                  converted: rule.amount,
                  fees: Money(rule.fees, rule.amount.currency),
                ),
                date: DateTime.now(),
                note: rule.note,
              ),
      ),
    ),
  );
  return saved != null;
}

/// Récurrences (canvas RecurrencesA): grouped by type, each with its
/// rhythm, amount and next date, « Nouvelle récurrence » at the bottom.
class RecurrencesScreen extends StatefulWidget {
  const RecurrencesScreen({super.key, required this.data});

  final EntryData data;

  @override
  State<RecurrencesScreen> createState() => _RecurrencesScreenState();
}

class _RecurrencesScreenState extends State<RecurrencesScreen> {
  List<RecurringInfo>? _rules;
  _Names? _names;

  RecurringRepository get _repo => widget.data.recurrences!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = [
      for (final r in await _repo.rules())
        if (!r.stopped) r,
    ];
    final names = await _Names.load(widget.data);
    if (!mounted) return;
    setState(() {
      _rules = rules;
      _names = names;
    });
  }

  Future<void> _add() async {
    if (await _openForm(context, widget.data)) await _load();
  }

  Future<void> _open(RecurringInfo r) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecurrenceScreen(data: widget.data, ruleId: r.id),
      ),
    );
    if (changed ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rules = _rules;
    final names = _names;
    return Scaffold(
      appBar: AppBar(title: Text(l.recurrencesTitle)),
      body: rules == null || names == null
          ? const SizedBox.shrink()
          : ListView(
              // The first group brings its own gap under the title bar.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: rules.isEmpty
                  ? [
                      EmptyCard(
                        icon: KibuoIcons.repeat,
                        title: l.recurrencesEmptyTitle,
                        help: l.recurrencesEmptyHelp,
                        action: l.recurrenceNew,
                        onAction: _add,
                      ),
                    ]
                  : [
                      for (final (kind, title) in [
                        (EntryKind.expense, l.recurrencesExpenses),
                        (EntryKind.income, l.recurrencesIncome),
                        (EntryKind.transfer, l.recurrencesTransfers),
                      ])
                        if (rules.any((r) => r.kind == kind)) ...[
                          // Its own gap above (DIRECTION: Groupes).
                          const SizedBox(height: GroupTitle.before),
                          GroupTitle(
                            title: title,
                            count:
                                '${rules.where((r) => r.kind == kind).length}',
                          ),
                          SettingsCard(
                            children: [
                              for (final r in rules)
                                if (r.kind == kind)
                                  _RuleRow(
                                    rule: r,
                                    names: names,
                                    onTap: () => _open(r),
                                  ),
                            ],
                          ),
                        ],
                      const SizedBox(height: 16),
                      KibuoButton(
                        label: l.recurrenceNew,
                        kind: ButtonKind.create,
                        icon: KibuoIcons.plusBold,
                        onPressed: _add,
                      ),
                    ],
            ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.rule,
    required this.names,
    required this.onTap,
  });

  final RecurringInfo rule;
  final _Names names;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final next = rule.upcoming(DateTime.now(), count: 1);
    final rhythm = rule.kind == EntryKind.transfer
        ? '${rhythmOnly(l, lang, rule.schedule)} · '
              '${l.recurrenceToAccount(names.account(rule.toAccountId))}'
        : rhythmOnly(l, lang, rule.schedule);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        child: Row(
          children: [
            _tile(rule, names, 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          names.title(l, rule),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.rowLabel,
                        ),
                      ),
                      if (rule.asDraft ?? false) ...[
                        const SizedBox(width: 6),
                        _Badge(l.recurrenceToValidate),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rhythm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.help,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _signed(rule, lang),
                  style: KibuoType.buttonSmall.copyWith(
                    color: kindColors(rule.kind).ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next.isEmpty
                      ? l.recurrenceNone
                      : l.recurrenceNextOn(
                          DateFormat.MMMd(lang).format(next.first),
                        ),
                  style: KibuoType.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KibuoColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: KibuoType.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation.weight(700)],
        ),
      ),
    );
  }
}

/// A recurrence's card (canvas RecurrenceFiche): the amount, the rhythm
/// and the next three dates, what it uses, the last times, « Modifier » and
/// « Arrêter la récurrence ». Pops true when something changed.
class RecurrenceScreen extends StatefulWidget {
  const RecurrenceScreen({super.key, required this.data, required this.ruleId});

  final EntryData data;
  final String ruleId;

  @override
  State<RecurrenceScreen> createState() => _RecurrenceScreenState();
}

class _RecurrenceScreenState extends State<RecurrenceScreen> {
  RecurringInfo? _rule;
  _Names? _names;
  List<TransactionInfo> _past = const [];
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rule = (await widget.data.recurrences!.rules())
        .where((r) => r.id == widget.ruleId)
        .firstOrNull;
    final names = await _Names.load(widget.data);
    final past = [
      for (final t in await widget.data.transactions.all(drafts: true))
        if (t.recurringId == widget.ruleId) t,
    ].take(5).toList();
    if (!mounted) return;
    setState(() {
      _rule = rule;
      _names = names;
      _past = past;
    });
  }

  Future<void> _edit() async {
    if (await _openForm(context, widget.data, rule: _rule)) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _stop() async {
    final l = AppLocalizations.of(context);
    final rule = _rule!;
    final name = _names!.title(l, rule);
    final sure = await confirmRemoval(
      context,
      title: l.recurrenceStopTitle(name),
      summary: RemovalSummary(
        leading: _tile(rule, _names!, 36),
        title: name,
        subtitle: rhythmOnly(
          l,
          Localizations.localeOf(context).languageCode,
          rule.schedule,
        ),
        trailing: _signed(rule, Localizations.localeOf(context).languageCode),
      ),
      text: l.recurrenceStopText,
      action: l.recurrenceStopAction,
    );
    if (!sure || !mounted) return;
    if (!await confirmWithCode(context, l.recurrenceStopTitle(name))) return;
    await widget.data.recurrences!.stop(rule.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final rule = _rule;
    final names = _names;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.recurrenceTitle),
          actions: [
            if (rule != null)
              TextAction(label: l.recurrenceEditAction, onPressed: _edit),
            const SizedBox(width: 8),
          ],
        ),
        body: rule == null || names == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  _hero(l, lang, rule, names),
                  const SizedBox(height: 16),
                  SettingsCard(
                    children: [
                      EntryField(
                        icon: KibuoIcons.wallet,
                        label: l.entryAccount,
                        value: names.account(rule.accountId),
                        trailing: names.accounts
                            .where((a) => a.id == rule.accountId)
                            .firstOrNull
                            ?.currency,
                      ),
                      if (rule.kind == EntryKind.transfer)
                        EntryField(
                          icon: KibuoIcons.arrowsLeftRight,
                          label: l.transferTo,
                          value: names.account(rule.toAccountId),
                        )
                      else
                        EntryField(
                          icon: KibuoIcons.tag,
                          label: l.entryCategory,
                          value: names.category(rule.categoryId) == null
                              ? null
                              : categoryName(
                                  l,
                                  names.category(rule.categoryId)!,
                                ),
                        ),
                      EntryField(
                        icon: KibuoIcons.repeat,
                        label: l.repeatEach,
                        value: rule.asDraft ?? false
                            ? l.recurrenceAskDraft
                            : l.recurrenceSaveDirect,
                      ),
                    ],
                  ),
                  if (_past.isNotEmpty) ...[
                    const SizedBox(height: GroupTitle.gap),
                    SectionTitle(l.recurrencePast),
                    SettingsCard(
                      children: [
                        for (final t in _past)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat.MMMMd(lang)
                                        .format(t.date.toLocal()),
                                    style: KibuoType.body,
                                  ),
                                ),
                                Text(
                                  switch (t.status) {
                                    'ignored' => l.recurrenceIgnored,
                                    'draft' => l.recurrenceDraft,
                                    _ => signedTotal(context, t),
                                  },
                                  style: KibuoType.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontVariations: const [
                                      FontVariation.weight(600),
                                    ],
                                    color: t.status == 'done'
                                        ? kindColors(t.kind).ink
                                        : KibuoColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SettingsCard(
                    children: [
                      SettingsRow(
                        label: l.recurrenceStop,
                        danger: true,
                        onTap: _stop,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  HelpText(l.recurrenceStopText),
                ],
              ),
      ),
    );
  }

  Widget _hero(
    AppLocalizations l,
    String lang,
    RecurringInfo rule,
    _Names names,
  ) {
    final colors = kindColors(rule.kind);
    final next = rule.upcoming(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.tint,
        border: Border.all(color: colors.edge, width: 1.5),
        borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tile(rule, names, 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(names.title(l, rule), style: KibuoType.itemName),
                    Text(
                      rhythmText(l, lang, rule.schedule),
                      style: KibuoType.help.copyWith(color: colors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _signed(rule, lang),
            style: KibuoType.bigAmount.copyWith(fontSize: 40, height: 46 / 40),
          ),
          const SizedBox(height: 10),
          Text(l.recurrenceNextTimes, style: KibuoType.caption),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: next.isEmpty
                ? [Text(l.recurrenceNone, style: KibuoType.help)]
                : [
                    for (final d in next)
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: KibuoColors.veil.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // As wide as its date, side by side.
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            d.year == DateTime.now().year
                                ? DateFormat.MMMd(lang).format(d)
                                : DateFormat.yMMMd(lang).format(d),
                            style: KibuoType.help.copyWith(
                              color: KibuoColors.ink,
                            ),
                          ),
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
