import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/amount_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/confirm_sheet.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/hatched_bar.dart';
import 'package:kibuo/ui/kit/operation_card.dart';
import 'package:kibuo/ui/kit/quick_amounts.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/value_row.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/projects/project_parts.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';

String _money(BuildContext context, Money m) => formatMoney(
  m,
  currencyOf(m.currency),
  Localizations.localeOf(context).languageCode,
);

/// « Mettre de côté pour Voyage » (canvas ProjetP1, ProjetMettreRefus);
/// once the goal is met, « Objectif atteint ». True when something moved.
Future<bool> putAsideFlow(
  BuildContext context, {
  required EntryData data,
  required ProjectRepository projects,
  required ProjectInfo project,
  DateTime Function() now = DateTime.now,
  Future<void> Function()? onSaved,
}) async {
  final accounts = [
    for (final a in await data.accounts.accounts())
      if (!a.archived && a.balance.currency == project.goal.currency) a,
  ];
  final free = {for (final a in accounts) a.id: await projects.free(a.id)};
  if (!context.mounted) return false;
  final l = AppLocalizations.of(context);
  final done = await showKibuoSheet<_Moved>(
    context,
    title: l.projectPutAsideFor(project.name),
    builder: (_) => _MoneySheet(
      projects: projects,
      project: project,
      accounts: accounts,
      free: free,
      now: now,
      put: true,
    ),
  );
  if (done == null || !context.mounted) return false;
  Haptics.confirm();
  // What lies behind is up to date under the confirmation.
  await onSaved?.call();
  final after = await projects.project(project.id);
  if (after == null || !context.mounted) return true;
  // Met: « Objectif atteint » says it (canvas ProjetAtteint).
  if (after.reached && !project.reached) {
    await reachedFlow(
      context,
      data: data,
      projects: projects,
      project: after,
      now: now,
    );
    return true;
  }
  final undo = await _confirmMoved(
    context,
    after: after,
    done: done,
    now: now(),
  );
  if (undo == true) {
    await projects.undo(done.moved);
    await onSaved?.call();
  }
  return true;
}

/// What a sheet moved: the amount, what was written, where it came from.
class _Moved {
  const _Moved(this.amount, this.moved, {this.from});

  final Money amount;
  final MoneyMoved moved;
  final String? from;
}

/// « Mis de côté », « Argent repris » (canvas ConfirmA): the line, the
/// project's bar after it, « Annuler »; it closes by itself. True to undo.
Future<bool?> _confirmMoved(
  BuildContext context, {
  required ProjectInfo after,
  required _Moved done,
  required DateTime now,
}) {
  final l = AppLocalizations.of(context);
  final put = done.amount.minor > 0;
  final where = done.from == null
      ? after.account
      : l.projectFromTo(done.from!, after.account);
  final shown = Money(done.amount.minor.abs(), done.amount.currency);
  return showConfirmSheet<bool>(
    context,
    title: put ? l.projectPutAsideSaved : l.projectTakenBackSaved,
    card: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SavedLine(
          title: after.name,
          subtitle: '$where · ${l.entryToday}',
          amount: '${put ? '+' : '−'}${_money(context, shown)}',
        ),
        const SizedBox(height: 6),
        ProjectBar(share: after.share, fill: KibuoColors.projectLine),
        Row(
          children: [
            Expanded(
              child: Text(
                l.projectProgress(
                  _money(context, after.saved),
                  _money(context, after.goal),
                ),
                style: KibuoType.caption,
              ),
            ),
            Text('${(after.share * 100).round()} %', style: KibuoType.caption),
          ],
        ),
      ],
    ),
    actions: [ConfirmAction(l.cancel, true)],
  );
}

/// « Reprendre de l'argent » (canvas ProjetReprendre): at most what is
/// set aside; nothing moves on the account. True once taken back.
Future<bool> takeBackFlow(
  BuildContext context, {
  required ProjectRepository projects,
  required ProjectInfo project,
  DateTime Function() now = DateTime.now,
  Future<void> Function()? onSaved,
}) async {
  final l = AppLocalizations.of(context);
  final done = await showKibuoSheet<_Moved>(
    context,
    title: l.projectTakeBack,
    builder: (_) => _MoneySheet(
      projects: projects,
      project: project,
      accounts: const [],
      free: const {},
      now: now,
      put: false,
    ),
  );
  if (done == null || !context.mounted) return false;
  Haptics.confirm();
  await onSaved?.call();
  final after = await projects.project(project.id);
  if (after == null || !context.mounted) return true;
  final undo = await _confirmMoved(
    context,
    after: after,
    done: done,
    now: now(),
  );
  if (undo == true) {
    await projects.undo(done.moved);
    await onSaved?.call();
  }
  return true;
}

enum _Quick { missing, period, half, all }

class _MoneySheet extends StatefulWidget {
  const _MoneySheet({
    required this.projects,
    required this.project,
    required this.accounts,
    required this.free,
    required this.now,
    required this.put,
  });

  final ProjectRepository projects;
  final ProjectInfo project;

  /// Where it may come from: the accounts in the project's currency.
  final List<AccountInfo> accounts;

  /// What each of them has free.
  final Map<String, Money> free;
  final DateTime Function() now;

  /// Setting aside; false: taking back.
  final bool put;

  @override
  State<_MoneySheet> createState() => _MoneySheetState();
}

class _MoneySheetState extends State<_MoneySheet> {
  ProjectInfo get _p => widget.project;
  late final ProjectPace _pace = ProjectPace.of(_p, widget.now());
  late final String _currency = _p.goal.currency;
  late AccountInfo? _account =
      widget.accounts.where((a) => a.id == _p.accountId).firstOrNull ??
      widget.accounts.firstOrNull;
  // What is offered first never goes beyond what may be taken: the
  // refusal is for what one types (owner, 24 November).
  late Money _amount = () {
    final start = _quickValue(_startQuick) ?? 0;
    final most = _most.minor < 0 ? 0 : _most.minor;
    return Money(start > most ? most : start, _currency);
  }();
  bool _saving = false;

  int get _missing => _p.goal.minor - _p.saved.minor;

  _Quick get _startQuick => !widget.put
      ? _Quick.all
      : _pace.per > 0 && _pace.per < _missing
      ? _Quick.period
      : _Quick.missing;

  int? _quickValue(_Quick q) => switch (q) {
    _Quick.missing => _missing > 0 ? _missing : null,
    _Quick.period => _pace.per > 0 && _pace.per < _missing ? _pace.per : null,
    _Quick.half => () {
      final unit = unitOf(_currency);
      final half = ((_missing / 2) / unit).ceil() * unit;
      return half > 0 && half < _missing ? half : null;
    }(),
    _Quick.all => _p.saved.minor > 0 ? _p.saved.minor : null,
  };

  Money get _free => widget.free[_account?.id] ?? Money(0, _currency);

  /// What it may take at most: what is free there, or what is set aside.
  Money get _most => widget.put ? _free : _p.saved;

  bool get _over => _amount.minor > _most.minor;

  bool get _ready =>
      _amount.minor > 0 && !_over && (!widget.put || _account != null);

  String _m(int minor) => _money(context, Money(minor, _currency));

  Future<void> _pickAmount() async {
    final l = AppLocalizations.of(context);
    final picked = await typeAmount(
      context,
      title: l.entryAmount,
      start: _amount,
      most: _most,
      cap: widget.put ? l.projectFreeCap : l.projectSavedCap,
    );
    if (picked != null) setState(() => _amount = picked);
  }

  Future<void> _pickAccount() async {
    final picked = await pickAccount(
      context,
      accounts: widget.accounts,
      current: _account?.id,
    );
    if (picked != null) setState(() => _account = picked);
  }

  Future<void> _save() async {
    if (!_ready || _saving) return;
    setState(() => _saving = true);
    final moved = widget.put
        ? await widget.projects.putAside(
            _p.id,
            amount: _amount.minor,
            date: widget.now(),
            fromAccountId: _account!.id,
          )
        : await widget.projects.takeBack(
            _p.id,
            amount: _amount.minor,
            date: widget.now(),
          );
    if (!mounted) return;
    if (moved != null) {
      final from = widget.put && _account!.id != _p.accountId
          ? _account!.name
          : null;
      Navigator.of(context).pop(
        _Moved(
          widget.put ? _amount : Money(-_amount.minor, _currency),
          moved,
          from: from,
        ),
      );
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final goal = _p.goal.minor <= 0 ? 1 : _p.goal.minor;
    final saved = _p.saved.minor;
    final after = widget.put ? saved + _amount.minor : saved - _amount.minor;
    final ink = widget.put ? KibuoColors.projectInk : KibuoColors.inkSecondary;
    final quick = <QuickAmount<_Quick>>[
      for (final q
          in widget.put
              ? const [_Quick.missing, _Quick.period, _Quick.half]
              : const [_Quick.all])
        if (_quickValue(q) case final v?)
          QuickAmount(
            value: q,
            amount: _m(v),
            label: switch (q) {
              _Quick.missing => l.projectQuickMissing,
              _Quick.period => switch (_p.period) {
                PlanPeriod.week => l.projectQuickWeek,
                PlanPeriod.fortnight => l.projectQuickFortnight,
                PlanPeriod.month => l.projectQuickMonth,
              },
              _Quick.half => l.projectQuickHalf,
              _Quick.all => l.projectQuickAll,
            },
          ),
    ];
    final chosen = quick
        .where((q) => _quickValue(q.value) == _amount.minor)
        .firstOrNull
        ?.value;
    final account = _account;
    final elsewhere =
        widget.put && account != null && account.id != _p.accountId;
    final left = _free.minor - _amount.minor;
    final low = account != null && left < (account.balance.minor * 0.1).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The project, its bar with the part being moved hatched.
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
                    flex: 2,
                    child: Text(
                      _p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.body.weight(700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 3,
                    child: Text(
                      projectWhen(l, lang, _p, widget.now(), left: false),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.caption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HatchedBar(
                done: (widget.put ? saved : after.clamp(0, saved)) / goal,
                after: ((widget.put ? after : saved) / goal).clamp(0, 1),
                ink: KibuoColors.projectLine,
                track: KibuoColors.projectTrack,
                hatch: widget.put
                    ? KibuoColors.projectLine.withValues(alpha: 0.45)
                    : KibuoColors.danger.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.projectSavedAmount(_m(saved)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.caption,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: '${widget.put ? '+' : '−'}${_m(_amount.minor)}',
                      style: TextStyle(color: ink).weight(700),
                      children: [
                        TextSpan(
                          text:
                              ' · ${(after.clamp(0, goal) / goal * 100).round()} %',
                        ),
                      ],
                    ),
                    style: KibuoType.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (quick.isNotEmpty) ...[
          const SizedBox(height: 12),
          QuickAmounts<_Quick>(
            items: quick,
            selected: chosen,
            onPick: (q) =>
                setState(() => _amount = Money(_quickValue(q) ?? 0, _currency)),
          ),
        ],
        const SizedBox(height: 12),
        SettingsCard(
          children: [
            ValueRow(
              label: l.entryAmount,
              value: _m(_amount.minor),
              onTap: _pickAmount,
              color: ink,
            ),
            if (widget.put)
              ValueRow(
                label: l.projectTakenFrom,
                value: account?.name ?? l.entryNoAccount,
                onTap: widget.accounts.length > 1 ? _pickAccount : null,
              )
            else
              ValueRow(label: l.projectSheetOn, value: _p.account),
          ],
        ),
        if (elsewhere) ...[
          const SizedBox(height: 12),
          NoticeCard(
            icon: KibuoIcons.arrowsLeftRight,
            text: l.projectTransferNote(account.name, _p.account),
            background: KibuoColors.projectTint,
            ink: KibuoColors.projectInk,
          ),
        ],
        if (widget.put && account != null) ...[
          const SizedBox(height: 12),
          if (_over)
            RefuseOnAppear(
              child: NoticeCard(
                icon: KibuoIcons.warningCircle,
                text: l.projectOnlyFree(_m(_free.minor), account.name),
                background: KibuoColors.dangerTint,
                ink: KibuoColors.danger,
              ),
            )
          else if (low)
            NoticeCard(
              icon: KibuoIcons.warning,
              text: l.projectWillLeave(_m(left), account.name),
              background: KibuoColors.warningSoft,
              ink: KibuoColors.warningSoftInk,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l.projectWillLeave(_m(left), account.name),
                style: KibuoType.help,
              ),
            ),
        ],
        if (!widget.put) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l.projectTakeBackNote(_m(_amount.minor), _p.account),
              style: KibuoType.help,
            ),
          ),
        ],
        const SizedBox(height: 16),
        KibuoButton(
          label: widget.put ? l.projectPutAside : l.projectTakeBackAction,
          kind: widget.put ? ButtonKind.primary : ButtonKind.dark,
          onPressed: _ready && !_saving ? _save : null,
        ),
        const SizedBox(height: 8),
        KibuoButton(
          label: l.later,
          kind: ButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

enum _Ending { spent, keep, release }

/// « Objectif atteint » (canvas ProjetAtteint): « Je l'ai dépensé » opens
/// a prefilled expense, and once saved the project ends; « Le garder de
/// côté » changes nothing; « Le rendre disponible » ends it, nothing
/// moves. True when the project ended.
Future<bool> reachedFlow(
  BuildContext context, {
  required EntryData data,
  required ProjectRepository projects,
  required ProjectInfo project,
  DateTime Function() now = DateTime.now,
}) async {
  final l = AppLocalizations.of(context);
  final today = now();
  final due = project.due;
  final early = due == null
      ? 0
      : DateTime.utc(
          due.year,
          due.month,
          due.day,
        ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  final amount = _money(context, project.saved);
  final text = early > 0
      ? l.projectReachedEarlyText(amount, project.name, early)
      : l.projectReachedText(amount, project.name);
  final choice = await showModalBottomSheet<_Ending>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      padding: sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 4),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KibuoColors.accentSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                KibuoIcons.checkBold,
                size: 32,
                color: KibuoColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.projectsReached,
            textAlign: TextAlign.center,
            style: KibuoType.sheetTitle,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: KibuoType.body.copyWith(
              fontSize: 15,
              color: KibuoColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(l.projectWhatNow, style: KibuoType.sectionTitle),
          ),
          const SizedBox(height: 8),
          SettingsCard(
            children: [
              _EndRow(
                icon: KibuoIcons.arrowDown,
                tint: KibuoColors.debtTint,
                ink: KibuoColors.debtInk,
                title: l.projectSpent,
                help: l.projectSpentHelp,
                onTap: () => Navigator.of(context).pop(_Ending.spent),
              ),
              _EndRow(
                icon: KibuoIcons.piggyBank,
                tint: KibuoColors.projectTint,
                ink: KibuoColors.projectInk,
                title: l.projectKeep,
                help: l.projectKeepHelp,
                onTap: () => Navigator.of(context).pop(_Ending.keep),
              ),
              _EndRow(
                icon: KibuoIcons.wallet,
                tint: KibuoColors.accentSoft,
                ink: KibuoColors.accent,
                title: l.projectRelease,
                help: l.projectReleaseHelp(project.account),
                onTap: () => Navigator.of(context).pop(_Ending.release),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return false;
  switch (choice) {
    case _Ending.spent:
      final id = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => EntryScreen(
            data: data,
            kind: EntryKind.expense,
            accountId: project.accountId,
            initial: TransactionInfo(
              id: '',
              kind: EntryKind.expense,
              accountId: project.accountId,
              categoryId: null,
              paid: project.saved,
              total: EntryTotal(
                kind: EntryKind.expense,
                converted: project.saved,
                fees: Money(0, project.saved.currency),
              ),
              date: now(),
              note: project.name,
            ),
          ),
        ),
      );
      // Given up, nothing changes (PRODUCT).
      if (id == null) return false;
      await projects.end(project.id, ending: 'spent', on: now());
      if (context.mounted) {
        Haptics.confirm();
        await showConfirmSheet<void>(
          context,
          title: l.projectEndedSaved(project.name),
          card: SavedLine(
            title: project.name,
            subtitle: l.projectSpentLine(project.account),
            amount: amount,
          ),
        );
      }
      return true;
    case _Ending.release:
      await projects.end(project.id, ending: 'released', on: now());
      if (!context.mounted) return true;
      Haptics.confirm();
      final undo = await showConfirmSheet<bool>(
        context,
        title: l.projectEndedSaved(project.name),
        card: SavedLine(
          title: project.name,
          subtitle: l.projectReleasedLine(project.account),
          amount: amount,
        ),
        actions: [ConfirmAction(l.cancel, true)],
      );
      if (undo == true) {
        await projects.reopen(project.id);
        return false;
      }
      return true;
    case _Ending.keep:
    case null:
      return false;
  }
}

/// A choice of « Objectif atteint »: its tile, title, what it does, ›.
class _EndRow extends StatelessWidget {
  const _EndRow({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    required this.help,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String title;
  final String help;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      Haptics.tap();
      onTap();
    },
    child: Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KibuoType.rowLabel.weight(600)),
                const SizedBox(height: 1),
                Text(help, style: KibuoType.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            KibuoIcons.caretRight,
            size: 18,
            color: KibuoColors.lineStrong,
          ),
        ],
      ),
    ),
  );
}
