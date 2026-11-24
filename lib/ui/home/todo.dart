import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/todo_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/todo/todo.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/backup_sheet.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/budgets/budget_detail_screen.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/home/drafts_sheet.dart';
import 'package:kibuo/ui/kit/dashed_border.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/recovery_screens.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/obligations/claim_sheet.dart';
import 'package:kibuo/ui/obligations/debt_screen.dart';
import 'package:kibuo/ui/obligations/debts_screen.dart';
import 'package:kibuo/ui/projects/project_money.dart';
import 'package:kibuo/ui/projects/project_parts.dart';
import 'package:kibuo/ui/projects/project_screen.dart';
import 'package:kibuo/ui/projects/projects_screen.dart' show projectIcon;
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/reminders/due_forecast.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/draft_screen.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// A line of « À traiter » with what its screens need.
class HomeTodo extends TodoItem {
  HomeTodo.budget(this.budget, {required bool over})
    : drafts = const [],
      currency = null,
      rateDays = 0,
      due = null,
      dueName = '',
      debt = null,
      project = null,
      projectLate = null,
      backupDays = null,
      super(
        kind: over ? TodoKind.budgetOver : TodoKind.budgetNear,
        key: 'budget:${budget?.budget.id}',
      );

  HomeTodo.drafts(this.drafts)
    : budget = null,
      currency = null,
      rateDays = 0,
      due = null,
      dueName = '',
      debt = null,
      project = null,
      projectLate = null,
      backupDays = null,
      super(kind: TodoKind.drafts, key: 'drafts');

  HomeTodo.recovery()
    : budget = null,
      drafts = const [],
      currency = null,
      rateDays = 0,
      due = null,
      dueName = '',
      debt = null,
      project = null,
      projectLate = null,
      backupDays = null,
      super(kind: TodoKind.recovery, key: 'recovery');

  HomeTodo.rate(this.currency, this.rateDays)
    : budget = null,
      drafts = const [],
      due = null,
      dueName = '',
      debt = null,
      project = null,
      projectLate = null,
      backupDays = null,
      super(kind: TodoKind.oldRate, key: 'rate:${currency?.code}');

  /// A date to come that would leave its account short (PRODUCT).
  HomeTodo.shortfall(DueItem this.due, this.dueName)
    : budget = null,
      drafts = const [],
      currency = null,
      rateDays = 0,
      debt = null,
      project = null,
      projectLate = null,
      backupDays = null,
      super(kind: TodoKind.shortfall, key: due.key);

  /// A debt or receivable late, due today or this week (PRODUCT).
  HomeTodo.debt(DebtLine this.debt, TodoKind kind)
    : budget = null,
      drafts = const [],
      currency = null,
      rateDays = 0,
      due = null,
      dueName = '',
      project = null,
      projectLate = null,
      backupDays = null,
      super(kind: kind, key: 'debt:${debt.id}');

  /// A project behind by a whole part of its plan (PRODUCT: Projets).
  HomeTodo.project(ProjectInfo this.project, this.projectLate)
    : budget = null,
      drafts = const [],
      currency = null,
      rateDays = 0,
      due = null,
      dueName = '',
      debt = null,
      backupDays = null,
      super(kind: TodoKind.projectLate, key: 'project:${project.id}');

  /// No backup for more than 7 days; [backupDays] null when there was never
  /// one (PRODUCT: Sauvegarde manuelle).
  HomeTodo.backup(this.backupDays)
    : budget = null,
      drafts = const [],
      currency = null,
      rateDays = 0,
      due = null,
      dueName = '',
      debt = null,
      project = null,
      projectLate = null,
      super(kind: TodoKind.backupOld, key: 'backup');

  final int? backupDays;

  final ProjectInfo? project;

  /// How far behind, in the project's currency.
  final Money? projectLate;

  final DebtLine? debt;

  final DueItem? due;
  final String dueName;

  final BudgetLine? budget;
  final List<(TransactionInfo, OperationLabels)> drafts;
  final CurrencyInfo? currency;
  final int rateDays;
}

/// Gathers « À traiter » from the modules there are (PRODUCT): budgets,
/// drafts, the recovery code, old rates; then leaves out what was put off.
class TodoLoader {
  TodoLoader({required this.data, this.budgets, this.store, this.lock});

  final EntryData data;
  final BudgetLoader? budgets;
  final TodoStore? store;
  final LockController? lock;

  /// Every line still to show, the most urgent first.
  Future<List<HomeTodo>> load(BuildContext context, DateTime now) async {
    final items = <HomeTodo>[];
    if (budgets case final budgets?) {
      final book = await budgets.load(periodOf(now).month);
      for (final line in book.lines) {
        final state = line.status.state;
        if (state == BudgetState.ok) continue;
        items.add(HomeTodo.budget(line, over: state == BudgetState.over));
      }
    }
    final drafts = [
      for (final t in await data.transactions.all(drafts: true))
        if (t.isDraft) t,
    ];
    if (drafts.isNotEmpty) {
      if (!context.mounted) return const [];
      items.add(
        HomeTodo.drafts([
          for (final t in drafts)
            (t, await OperationLabels.of(context, data, t)),
        ]),
      );
    }
    // Short in the next three days (PRODUCT: Rappels).
    final soon = [
      for (final d in await dueForecast(data, now, days: 3))
        if (d.missing != null) d,
    ];
    if (soon.isNotEmpty) {
      if (!context.mounted) return const [];
      final name = await dueNames(data, AppLocalizations.of(context));
      for (final d in soon) {
        items.add(HomeTodo.shortfall(d, name(d)));
      }
    }
    // Debts: late or due today, urgent; due within 7 days, this week.
    for (final d in await data.debts?.debts() ?? const <DebtLine>[]) {
      if (d.settled || d.due == null) continue;
      final (state, days) = debtState(d, now);
      final owe = d.direction == DebtDirection.owe;
      if (state == DebtState.late || state == DebtState.today) {
        items.add(
          HomeTodo.debt(d, owe ? TodoKind.debtLate : TodoKind.receivableLate),
        );
      } else if (days != null && days <= 7) {
        items.add(HomeTodo.debt(d, TodoKind.debtSoon));
      }
    }
    // Projects behind by a whole part of their plan.
    for (final p in await data.projects?.projects() ?? const <ProjectInfo>[]) {
      final due = p.due;
      if (!p.running || due == null) continue;
      if (!lateForTodo(
        goal: p.goal.minor,
        saved: p.saved.minor,
        start: p.startedOn,
        due: due,
        today: now,
        period: p.period,
      )) {
        continue;
      }
      final pace = ProjectPace.of(p, now);
      items.add(HomeTodo.project(p, Money(-pace.gap, p.goal.currency)));
    }
    // No backup for more than 7 days.
    if (data.backups case final backups?) {
      final state = await backups.state();
      if (state.old(now)) {
        final last = state.last;
        items.add(
          HomeTodo.backup(last == null ? null : backupAgeDays(last, now)),
        );
      }
    }
    final lock = this.lock;
    if (lock != null &&
        lock.recovery != null &&
        lock.recoveryCreatedAt != null &&
        !lock.settings.recoveryVerified) {
      items.add(HomeTodo.recovery());
    }
    final main = await data.currencies.primaryCurrency();
    if (main != null) {
      final codes = {for (final a in await data.accounts.accounts()) a.currency}
        ..remove(main);
      for (final code in codes) {
        final rate = await data.currencies.latestRate(main, code);
        // In the phone's own days, not universal time's.
        final setOn = rate?.setOn.toLocal();
        if (setOn == null || !rateIsOld(setOn, now)) continue;
        final from = DateTime(setOn.year, setOn.month, setOn.day);
        final today = DateTime(now.year, now.month, now.day);
        items.add(
          HomeTodo.rate(
            await data.currencies.currency(code),
            today.difference(from).inDays,
          ),
        );
      }
    }
    final putOff = await store?.putOff() ?? PutOff.empty;
    return sortTodos(putOff.visible(items, now));
  }
}

/// What « À traiter » does: opens, acts, puts off, and reloads after.
class TodoActions {
  const TodoActions({
    required this.data,
    required this.reload,
    this.budgets,
    this.store,
    this.lock,
  });

  final EntryData data;
  final BudgetLoader? budgets;
  final TodoStore? store;
  final LockController? lock;
  final Future<void> Function() reload;

  /// The line's action, or the line touched: both open the same place.
  Future<void> open(BuildContext context, HomeTodo item) async {
    switch (item.kind) {
      case TodoKind.budgetOver || TodoKind.budgetNear:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => BudgetDetailScreen(
              loader: budgets!,
              month: periodOf(DateTime.now()).month,
              budgetId: item.budget!.budget.id,
            ),
          ),
        );
      case TodoKind.drafts:
        await showDraftsSheet(context, data, item.drafts);
      case TodoKind.recovery:
        await renewRecoveryCode(context, lock!);
      case TodoKind.shortfall:
        await openRuleCard(context, data, item.due!.planned.rule.id);
      case TodoKind.oldRate:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => CurrenciesScreen(repository: data.currencies),
          ),
        );
      case TodoKind.debtLate:
        final debts = data.debts;
        final detail = await debts?.detail(item.debt!.id);
        if (detail == null || !context.mounted) break;
        await repayDebt(context, data: data, debts: debts!, detail: detail);
      case TodoKind.receivableLate:
        await showClaimSheet(context, item.debt!);
      case TodoKind.debtSoon:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                DebtScreen(data: data, debts: data.debts!, id: item.debt!.id),
          ),
        );
      case TodoKind.backupOld:
        await runBackup(context, data.backups!);
      case TodoKind.projectLate:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ProjectScreen(
              data: data,
              projects: data.projects!,
              id: item.project!.id,
            ),
          ),
        );
    }
    await reload();
  }

  /// The line's action: for a late project, straight to « Mettre de
  /// côté »; for the others, where the line leads.
  Future<void> act(BuildContext context, HomeTodo item) async {
    if (item.kind != TodoKind.projectLate) return open(context, item);
    await putAsideFlow(
      context,
      data: data,
      projects: data.projects!,
      project: item.project!,
    );
    await reload();
  }

  /// « Plus tard »: away until tomorrow, with « Annuler » a moment.
  Future<void> putOff(BuildContext context, HomeTodo item, String name) async {
    final store = this.store;
    if (store == null) return;
    final l = AppLocalizations.of(context);
    await store.putOffToday(item.key, DateTime.now());
    await reload();
    if (!context.mounted) return;
    showKibuoToast(
      context,
      l.todoPutOff(name),
      action: l.toastUndo,
      onAction: () async {
        await store.bringBack(item.key);
        await reload();
      },
    );
  }
}

/// How a line reads: its tile, title, second line and action.
class TodoLook {
  TodoLook._({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.name,
    this.dashed = false,
    this.subColor,
  });

  /// The second line's colour, when it is not the group's.
  final Color? subColor;

  final IconData icon;
  final Color tint;
  final Color ink;
  final String title;
  final String subtitle;
  final String action;

  /// What « Reporté à demain : … » names.
  final String name;

  /// The drafts' tile is dashed, like a draft.
  final bool dashed;

  static TodoLook of(BuildContext context, HomeTodo item) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    switch (item.kind) {
      case TodoKind.budgetOver || TodoKind.budgetNear:
        final line = item.budget!;
        final name = categoryName(l, line.category);
        final over = item.kind == TodoKind.budgetOver;
        final left = line.status.left;
        return TodoLook._(
          icon: KibuoIcons.chartPieSlice,
          tint: over ? KibuoColors.dangerTint : KibuoColors.warningTint,
          ink: over ? KibuoColors.danger : KibuoColors.warningInk,
          title: '$name · ${line.status.percent} %',
          subtitle: over
              ? l.todoBudgetOverSub
              : l.todoBudgetNearSub(
                  formatMoney(left, currencyOf(left.currency), lang),
                ),
          action: l.todoSee,
          name: name,
        );
      case TodoKind.drafts:
        final title = l.todoDrafts(item.drafts.length);
        return TodoLook._(
          icon: KibuoIcons.repeat,
          tint: KibuoColors.fillSoft,
          ink: KibuoColors.inkSecondary,
          title: title,
          subtitle: [
            for (final (t, labels) in item.drafts) draftName(t, labels),
          ].join(', '),
          action: l.todoValidate,
          name: title,
          dashed: true,
        );
      case TodoKind.shortfall:
        final due = item.due!;
        final missing = due.missing!;
        return TodoLook._(
          icon: KibuoIcons.warning,
          tint: KibuoColors.warningTint,
          ink: KibuoColors.warningInk,
          title: l.todoShortfall(
            item.dueName,
            DateFormat.MMMd(lang).format(due.planned.day),
          ),
          subtitle: l.todoShortfallSub(
            formatMoney(missing, currencyOf(missing.currency), lang),
            due.account.name,
          ),
          action: l.todoSee,
          name: item.dueName,
          subColor: KibuoColors.warningInk,
        );
      case TodoKind.recovery:
        return TodoLook._(
          icon: KibuoIcons.key,
          tint: KibuoColors.dangerTint,
          ink: KibuoColors.danger,
          title: l.todoRecovery,
          subtitle: l.todoRecoverySub,
          action: l.todoRecoveryAction,
          name: l.todoRecovery,
        );
      case TodoKind.debtLate || TodoKind.receivableLate || TodoKind.debtSoon:
        final d = item.debt!;
        final owe = d.direction == DebtDirection.owe;
        final urgent = item.kind != TodoKind.debtSoon;
        final word = debtWord(l, d, DateTime.now());
        return TodoLook._(
          icon: KibuoIcons.handCoins,
          tint: owe ? KibuoColors.debtTint : KibuoColors.accentTintStrong,
          ink: owe ? KibuoColors.debtInk : KibuoColors.accent,
          title:
              '${d.person} · '
              '${formatMoney(d.left, currencyOf(d.left.currency), lang)}',
          subtitle:
              '${owe ? l.debtTagOwe : l.debtTagOwed} · '
              '${word[0].toLowerCase()}${word.substring(1)}',
          action: switch (item.kind) {
            TodoKind.debtLate => l.debtRepay,
            TodoKind.receivableLate => l.debtClaimAction,
            _ => l.todoSee,
          },
          name: d.person,
          subColor: urgent ? KibuoColors.danger : null,
        );
      case TodoKind.projectLate:
        final p = item.project!;
        final late = item.projectLate!;
        final due = p.due!;
        final days = DateTime.utc(due.year, due.month, due.day)
            .difference(
              DateTime.utc(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            )
            .inDays;
        return TodoLook._(
          icon: projectIcon(p.icon),
          tint: KibuoColors.projectTint,
          ink: KibuoColors.projectInk,
          title:
              '${p.name} · ${formatMoney(late, currencyOf(late.currency), lang)}',
          subtitle: days > 0 ? l.todoProjectLateLeft(days) : l.todoProjectLate,
          action: l.projectPutAside,
          name: p.name,
          subColor: KibuoColors.danger,
        );
      case TodoKind.backupOld:
        final days = item.backupDays;
        return TodoLook._(
          icon: KibuoIcons.downloadSimple,
          tint: KibuoColors.background,
          ink: KibuoColors.inkSecondary,
          title: l.todoBackup,
          subtitle: days == null ? l.todoBackupNone : l.todoBackupSub(days),
          action: l.todoBackupAction,
          name: l.todoBackup,
        );
      case TodoKind.oldRate:
        final title = l.todoRate(
          currencyName(context, item.currency!).toLowerCase(),
        );
        return TodoLook._(
          icon: KibuoIcons.currencyCircleDollar,
          tint: KibuoColors.background,
          ink: KibuoColors.inkSecondary,
          title: title,
          subtitle: l.todoRateSub(item.rateDays),
          action: l.todoRateAction,
          name: title,
        );
    }
  }
}

/// The colour of a group's dot; none for reminders (DIRECTION).
Color? todoDot(TodoGroup? group) => switch (group) {
  TodoGroup.urgent => KibuoColors.danger,
  TodoGroup.week => KibuoColors.warningInk,
  _ => null,
};

/// Lines of « À traiter » in one white card, each one swiped left to put
/// it off (canvas Aujourdhui, TraiterListe).
class TodoCard extends StatelessWidget {
  const TodoCard({super.key, required this.items, required this.actions});

  final List<HomeTodo> items;
  final TodoActions actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      // A line slid away goes past the card's edge (owner, 18 November).
      clipBehavior: Clip.none,
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
                color: KibuoColors.background,
              ),
            _TodoRow(
              key: ValueKey(item.key),
              item: item,
              actions: actions,
              corners: BorderRadius.vertical(
                top: Radius.circular(i == 0 ? KibuoTheme.radiusCard : 0),
                bottom: Radius.circular(
                  i == items.length - 1 ? KibuoTheme.radiusCard : 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.item,
    required this.actions,
    required this.corners,
  });

  final HomeTodo item;
  final TodoActions actions;

  /// Its corners in the card: the first and the last are round.
  final BorderRadius corners;

  @override
  Widget build(BuildContext context) {
    final look = TodoLook.of(context, item);
    final urgent = item.group == TodoGroup.urgent;
    final tile = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: look.tint,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      ),
      child: Icon(look.icon, size: 18, color: look.ink),
    );
    final row = InkWell(
      onTap: () => actions.open(context, item),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          // The home cards' margin, the action's › at 12 (DIRECTION).
          padding: const EdgeInsets.only(left: 14, right: 12),
          child: Row(
            children: [
              if (look.dashed)
                DashedBorder(
                  radius: KibuoTheme.radiusPill,
                  color: KibuoColors.inkMuted,
                  child: tile,
                )
              else
                tile,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      look.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.caption.copyWith(
                        color:
                            look.subColor ??
                            (urgent
                                ? KibuoColors.danger
                                : KibuoColors.inkSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => actions.act(context, item),
                borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
                child: SizedBox(
                  height: KibuoTheme.heightTouch,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        look.action,
                        style: KibuoType.help.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                          color: urgent
                              ? KibuoColors.danger
                              : KibuoColors.accent,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        KibuoIcons.caretRight,
                        size: 18,
                        color: urgent ? KibuoColors.danger : KibuoColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return SwipeToPutOff(
      corners: corners,
      label: AppLocalizations.of(context).todoLater,
      onPutOff: () => actions.putOff(context, item, look.name),
      child: row,
    );
  }
}

/// A line that slides left to show « Plus tard » (DIRECTION). Let go
/// before half its width, the button stays until a touch elsewhere; past
/// half, the line is put off at once.
class SwipeToPutOff extends StatefulWidget {
  const SwipeToPutOff({
    super.key,
    required this.child,
    required this.label,
    required this.onPutOff,
    this.corners = BorderRadius.zero,
  });

  final Widget child;
  final String label;
  final VoidCallback onPutOff;

  /// Its corners at rest; once moved, it is a card of its own, round all
  /// round, that goes past the edge.
  final BorderRadius corners;

  static const buttonWidth = 96.0;

  @override
  State<SwipeToPutOff> createState() => _SwipeToPutOffState();
}

class _SwipeToPutOffState extends State<SwipeToPutOff>
    with SingleTickerProviderStateMixin {
  late final _slide = AnimationController.unbounded(vsync: this);
  double _width = 1;
  bool _gone = false;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  TickerFuture _to(double x) => _slide.animateTo(
    x,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
  );

  void _close() {
    if (_slide.value != 0) _to(0);
  }

  void _putOff() {
    if (_gone) return;
    _gone = true;
    _to(-_width).then((_) => widget.onPutOff());
  }

  void _end(DragEndDetails d) {
    final shift = -_slide.value;
    if (shift > _width / 2 || d.primaryVelocity! < -1600) {
      _putOff();
    } else if (shift > SwipeToPutOff.buttonWidth / 3) {
      _to(-SwipeToPutOff.buttonWidth);
    } else {
      _to(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _width = box.maxWidth;
        return TapRegion(
          onTapOutside: (_) => _close(),
          child: GestureDetector(
            onHorizontalDragUpdate: (d) {
              final was = -_slide.value > _width / 2;
              _slide.value = (_slide.value + d.delta.dx).clamp(-_width, 0);
              // Past the middle, letting go puts it off: felt once.
              if (!was && -_slide.value > _width / 2) Haptics.refuse();
            },
            onHorizontalDragEnd: _end,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: KibuoColors.warningTint,
                      borderRadius: widget.corners,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: SwipeToPutOff.buttonWidth,
                        child: Semantics(
                          button: true,
                          child: InkWell(
                            onTap: _putOff,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  KibuoIcons.clock,
                                  size: 20,
                                  color: KibuoColors.warningInk,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.label,
                                  style: KibuoType.caption.copyWith(
                                    color: KibuoColors.warningInk,
                                    fontWeight: FontWeight.w600,
                                    fontVariations: const [
                                      FontVariation.weight(600),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _slide,
                  builder: (context, child) {
                    // From its place in the card to a card of its own.
                    final t = (-_slide.value / 24).clamp(0.0, 1.0);
                    final round = BorderRadius.lerp(
                      widget.corners,
                      BorderRadius.circular(KibuoTheme.radiusCard),
                      t,
                    )!;
                    return Transform.translate(
                      offset: Offset(_slide.value, 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: round,
                          boxShadow: [
                            BoxShadow(
                              color: KibuoColors.ink.withValues(
                                alpha: 0.10 * t,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: KibuoColors.surface,
                          borderRadius: round,
                          clipBehavior: Clip.antiAlias,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// « À traiter » on the home: its dot, at most 3 lines, and « Tout voir ·
/// 9 › » when there are more (PRODUCT). Nothing at all without a line.
class TodoSection extends StatelessWidget {
  const TodoSection({
    super.key,
    required this.items,
    required this.actions,
    required this.onSeeAll,
  });

  final List<HomeTodo> items;
  final TodoActions actions;
  final VoidCallback onSeeAll;

  static const shown = 3;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final more = items.length > shown;
    final dot = todoDot(mostUrgent(items));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GroupTitle.before),
        GroupTitle(
          title: l.todoTitle,
          leading: dot == null ? null : _Dot(dot),
          trailing: more ? SeeAll(l.todoSeeAll('${items.length}')) : null,
          onTap: more ? onSeeAll : null,
        ),
        TodoCard(items: items.take(shown).toList(), actions: actions),
      ],
    );
  }
}

/// « Tout voir › », green, at the right of a group title.
class SeeAll extends StatelessWidget {
  const SeeAll(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: KibuoType.body.copyWith(
          color: KibuoColors.accent,
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation.weight(600)],
        ),
      ),
      const SizedBox(width: 2),
      const Icon(KibuoIcons.caretRight, size: 16, color: KibuoColors.accent),
    ],
  );
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// « À traiter », the whole list (canvas TraiterListe): Urgent, Cette
/// semaine and Rappels, each with its dot.
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({
    super.key,
    required this.loader,
    required this.actions,
  });

  final TodoLoader loader;

  /// Its reload is replaced by this screen's own.
  final TodoActions actions;

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<HomeTodo>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.loader.load(context, DateTime.now());
    if (mounted) setState(() => _items = items);
    await widget.actions.reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = _items;
    final a = widget.actions;
    final actions = TodoActions(
      data: a.data,
      budgets: a.budgets,
      store: a.store,
      lock: a.lock,
      reload: _load,
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.todoTitle),
            if (items != null)
              Text(l.todoListHelp(items.length), style: KibuoType.help),
          ],
        ),
      ),
      body: items == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                for (final (group, title) in [
                  (TodoGroup.urgent, l.todoUrgent),
                  (TodoGroup.week, l.todoWeek),
                  (TodoGroup.reminders, l.todoReminders),
                ])
                  if (items.any((t) => t.group == group)) ...[
                    const SizedBox(height: GroupTitle.before),
                    GroupTitle(
                      title: title,
                      count: '${items.where((t) => t.group == group).length}',
                      leading: _Dot(todoDot(group) ?? KibuoColors.inkSecondary),
                    ),
                    TodoCard(
                      items: [
                        for (final t in items)
                          if (t.group == group) t,
                      ],
                      actions: actions,
                    ),
                  ],
              ],
            ),
    );
  }
}
