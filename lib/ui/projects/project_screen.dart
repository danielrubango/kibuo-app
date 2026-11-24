import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/card_arrow.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/status_pill.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/projects/new_project_screen.dart';
import 'package:kibuo/ui/projects/project_money.dart';
import 'package:kibuo/ui/projects/project_parts.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// A project's card (canvas FicheProjet, FicheProjetSansDate,
/// ProjetTermine): where it stands, the plan by period, the payments,
/// « Reprendre de l'argent »; « Mettre de côté » at the bottom while it
/// runs. An ended project is only read, and may be deleted.
class ProjectScreen extends StatefulWidget {
  const ProjectScreen({
    super.key,
    required this.data,
    required this.projects,
    required this.id,
    this.now = DateTime.now,
    this.onChanged,
  });

  final EntryData data;
  final ProjectRepository projects;
  final String id;
  final DateTime Function() now;

  /// Money moved or the project changed: the home's available amount too.
  final VoidCallback? onChanged;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  ProjectInfo? _p;
  List<ContributionLine> _lines = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await widget.projects.project(widget.id);
    final lines = await widget.projects.contributions(widget.id);
    if (!mounted) return;
    if (p == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _p = p;
      _lines = lines;
    });
  }

  Future<void> _changed() async {
    widget.onChanged?.call();
    await _load();
  }

  Future<void> _putAside() async {
    final p = _p;
    if (p == null) return;
    final moved = await putAsideFlow(
      context,
      data: widget.data,
      projects: widget.projects,
      project: p,
      now: widget.now,
      onSaved: _changed,
    );
    if (moved) await _changed();
  }

  Future<void> _takeBack() async {
    final p = _p;
    if (p == null) return;
    if (await takeBackFlow(
      context,
      projects: widget.projects,
      project: p,
      now: widget.now,
      onSaved: _changed,
    )) {
      await _changed();
    }
  }

  Future<void> _whatNow() async {
    final p = _p;
    if (p == null) return;
    if (await reachedFlow(
      context,
      data: widget.data,
      projects: widget.projects,
      project: p,
      now: widget.now,
    )) {
      await _changed();
    }
  }

  Future<void> _edit() async {
    final p = _p;
    if (p == null) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NewProjectScreen(
          data: widget.data,
          projects: widget.projects,
          now: widget.now,
          editing: p,
          payments: _lines.length,
        ),
      ),
    );
    if (done == true) await _changed();
  }

  Future<void> _setRemind(bool on) async {
    final p = _p;
    if (p == null) return;
    await widget.projects.setRemind(p.id, remind: on);
    await _changed();
  }

  Future<void> _delete() async {
    final p = _p;
    if (p == null) return;
    if (await deleteProject(
      context,
      projects: widget.projects,
      project: p,
      payments: _lines.length,
    )) {
      widget.onChanged?.call();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = _p;
    if (p == null) return const Scaffold(body: SizedBox.shrink());
    final now = widget.now();
    final adding = p.running && !p.reached;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ProjectTile(icon: p.icon, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          if (p.running)
            TextButton(
              onPressed: _edit,
              child: Text(
                l.projectEdit,
                style: KibuoType.buttonSmall.copyWith(
                  color: KibuoColors.accent,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Hero(
            project: p,
            now: now,
            money: context.money,
            onWhatNow: _whatNow,
          ),
          if (ProjectPace.of(p, now).dated) ...[
            const SizedBox(height: 14),
            _Plan(
              project: p,
              now: now,
              money: context.money,
              remind: _RemindRow(project: p, onChanged: _setRemind),
            ),
          ] else if (p.running && !p.reached) ...[
            // Without a plan, its own small card (PRODUCT: Projets).
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
              ),
              child: _RemindRow(project: p, onChanged: _setRemind),
            ),
          ],
          if (_lines.isNotEmpty) ...[
            const SizedBox(height: GroupTitle.gap),
            GroupTitle(title: l.projectPayments, count: '${_lines.length}'),
            _Payments(lines: _lines, money: context.money),
          ],
          if (p.running && p.saved.minor > 0)
            ActionUnderCard(label: l.projectTakeBack, onPressed: _takeBack),
          if (!p.running)
            ActionUnderCard(
              label: l.projectDelete,
              color: KibuoColors.danger,
              onPressed: _delete,
            ),
        ],
      ),
      bottomNavigationBar: adding
          ? BottomAction(
              child: KibuoButton(
                label: l.projectPutAside,
                onPressed: _putAside,
              ),
            )
          : null,
    );
  }
}

/// « Supprimer Voyage ? » (canvas ProjetSupprimer): the project and its
/// payments go, the money is free again. True once deleted.
Future<bool> deleteProject(
  BuildContext context, {
  required ProjectRepository projects,
  required ProjectInfo project,
  required int payments,
}) async {
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final money = formatMoney(
    project.saved,
    currencyOf(project.saved.currency),
    lang,
  );
  final held = project.running && project.saved.minor > 0;
  final sure = await confirmRemoval(
    context,
    title: l.projectDeleteTitle(project.name),
    summary: Row(
      children: [
        ProjectTile(icon: project.icon, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KibuoType.itemName,
          ),
        ),
        Text(money, style: KibuoType.cardTitle),
      ],
    ),
    text:
        l.projectDeleteText(payments) +
        (held ? l.projectDeleteFree(money, project.account) : ''),
    action: l.projectDeleteAction,
  );
  if (!sure) return false;
  await projects.delete(project.id);
  return true;
}

/// Where it stands: the date and the time left, the tag, what is set
/// aside on the goal, the bar and its mark, ahead or behind and the
/// account; then what the date asks per period.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.project,
    required this.now,
    required this.money,
    required this.onWhatNow,
  });

  final ProjectInfo project;
  final DateTime now;
  final String Function(Money) money;
  final VoidCallback onWhatNow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = project;
    final pace = ProjectPace.of(p, now);
    final cur = p.goal.currency;
    final ended = !p.running;
    final endedOn = p.endedOn;
    final head = ended && endedOn != null
        ? l.projectEndedOn(DateFormat.MMMd(lang).format(endedOn))
        : p.due == null
        ? l.projectsNoDate
        : l.projectsBefore(DateFormat.MMMMd(lang).format(p.due!));
    final side = ended
        ? (p.ending == 'spent' ? l.projectSpentWord : l.projectReleasedWord)
        : p.due == null
        ? null
        : projectTimeLeft(l, now, p.due!);
    final pill = ended
        ? StatusPill(
            text: l.projectEndedTag,
            ink: KibuoColors.inkSecondary,
            tint: KibuoColors.background,
          )
        : pace.late
        ? StatusPill(
            text: l.projectsLate,
            ink: KibuoColors.danger,
            tint: KibuoColors.dangerTint,
          )
        : pace.ahead
        ? StatusPill(
            text: l.projectAheadTag,
            ink: KibuoColors.accent,
            tint: KibuoColors.accentSoft,
          )
        : null;
    final fill = ended
        ? KibuoColors.lineStrong
        : pace.late
        ? KibuoColors.danger
        : KibuoColors.projectLine;
    final small = KibuoType.body.copyWith(
      fontSize: 13,
      color: KibuoColors.inkSecondary,
    );
    final Widget state;
    if (ended) {
      state = Text(
        p.reached && endedOn != null && p.due != null
            ? l.projectReachedEarly(
                DateTime.utc(p.due!.year, p.due!.month, p.due!.day)
                    .difference(
                      DateTime.utc(endedOn.year, endedOn.month, endedOn.day),
                    )
                    .inDays
                    .clamp(0, 99999),
              )
            : '',
        style: small,
      );
    } else if (p.reached) {
      state = const SizedBox.shrink();
    } else if (!pace.dated) {
      state = Text(
        l.projectsOwnPace,
        style: small.copyWith(color: KibuoColors.ink).weight(700),
      );
    } else {
      state = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: pace.late
                  ? l.projectsBehind(money(Money(-pace.gap, cur)))
                  : pace.ahead
                  ? l.projectsAhead(money(Money(pace.gap, cur)))
                  : l.projectsOnTrack,
              style: TextStyle(
                color: pace.late
                    ? KibuoColors.danger
                    : pace.ahead
                    ? KibuoColors.accent
                    : KibuoColors.ink,
              ).weight(700),
            ),
            if (pace.late || pace.ahead) TextSpan(text: l.projectOnPace),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: small,
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, CardArrow.edge + 2, 16),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 22,
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: head,
                      children: [
                        if (side != null)
                          TextSpan(
                            text: ' · $side',
                            style: const TextStyle(
                              color: KibuoColors.inkSecondary,
                            ).weight(500),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.body.weight(600),
                  ),
                ),
                if (pill != null) ...[const SizedBox(width: 8), pill],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(
                money(p.saved),
                style: KibuoType.bigAmount.copyWith(height: 40 / 34),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l.projectsOf(money(p.goal)),
                  style: small.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProjectBar(share: p.share, mark: pace.mark, fill: fill, height: 10),
          const SizedBox(height: 8),
          if (p.running && p.reached)
            // « Objectif atteint · Et maintenant ? », the card's arrow at
            // the edge (owner, 24 November).
            InkWell(
              onTap: () {
                Haptics.tap();
                onWhatNow();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: l.projectsReached,
                          style: const TextStyle(color: KibuoColors.accent)
                              .weight(700),
                          children: [
                            TextSpan(
                              text: ' · ${l.projectWhatNow}',
                              style: const TextStyle(color: KibuoColors.ink)
                                  .weight(600),
                            ),
                          ],
                        ),
                        style: small,
                      ),
                    ),
                    const CardArrow(),
                  ],
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: state),
                const SizedBox(width: 12),
                // Always at the right edge (owner, 24 November).
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    l.projectOn(p.account),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: small,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// « Le plan · par semaine », what is left, the part per period in large,
/// then a tile per period from the one running today, sliding sideways.
class _Plan extends StatelessWidget {
  const _Plan({
    required this.project,
    required this.now,
    required this.money,
    required this.remind,
  });

  final ProjectInfo project;
  final DateTime now;
  final String Function(Money) money;

  /// « Me le rappeler », at the bottom (canvas FicheProjet).
  final Widget remind;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = project;
    final cur = p.goal.currency;
    final due = p.due!;
    final parts = planParts(
      goal: p.goal.minor,
      saved: p.saved.minor,
      today: now,
      due: due,
      period: p.period,
      unit: unitOf(cur),
    );
    if (parts.isEmpty) return const SizedBox.shrink();
    final per = projectPerWord(l, p.period);
    String name(int i) => switch (p.period) {
      PlanPeriod.week => i == 0 ? l.projectThisWeek : l.projectWeekN(i + 1),
      PlanPeriod.fortnight =>
        i == 0 ? l.projectThisFortnight : l.projectFortnightN(i + 1),
      PlanPeriod.month =>
        i == 0
            ? l.projectThisMonth
            : _upper(DateFormat.MMM(lang).format(parts[i].start)),
    };
    String days(PlanPart part) {
      final d = DateFormat.d(lang);
      final md = DateFormat.MMMd(lang);
      return part.start.month == part.end.month
          ? '${d.format(part.start)}–${md.format(part.end)}'
          : '${md.format(part.start)}–${md.format(part.end)}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
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
                    text: l.projectPlan,
                    children: [
                      TextSpan(
                        text: ' · $per',
                        style: const TextStyle(color: KibuoColors.inkSecondary)
                            .weight(500),
                      ),
                    ],
                  ),
                  style: KibuoType.body.weight(600),
                ),
              ),
              Text(
                l.projectPlanLeft(
                  money(Money(p.goal.minor - p.saved.minor, cur)),
                ),
                style: KibuoType.caption.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              Text(
                money(Money(parts.first.amount, cur)),
                style: KibuoType.cardTitle.copyWith(fontSize: 22),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '$per ${l.projectUntil(DateFormat.MMMMd(lang).format(parts.last.end))}',
                  style: KibuoType.caption.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.88, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: parts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final now = i == 0;
                  return Container(
                    width: 96,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: now ? KibuoColors.surface : KibuoColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: now
                            ? KibuoColors.projectInk
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name(i),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.caption
                              .copyWith(
                                color: now
                                    ? KibuoColors.projectInk
                                    : KibuoColors.inkSecondary,
                              )
                              .weight(700),
                        ),
                        Text(
                          days(parts[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.caption.copyWith(
                            fontSize: 11,
                            color: KibuoColors.inkMuted,
                          ),
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            money(Money(parts[i].amount, cur)),
                            maxLines: 1,
                            style: KibuoType.cardTitle.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: KibuoColors.background),
          Padding(padding: const EdgeInsets.only(top: 4), child: remind),
        ],
      ),
    );
  }
}

/// « Me le rappeler » and its rhythm under it, with its switch.
class _RemindRow extends StatelessWidget {
  const _RemindRow({required this.project, required this.onChanged});

  final ProjectInfo project;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SwitchRow(
      value: project.remind,
      onChanged: onChanged,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.projectRemindShort, style: KibuoType.rowLabel),
          Text(switch (project.period) {
            PlanPeriod.week => l.projectRemindWeek,
            PlanPeriod.fortnight => l.projectRemindFortnight,
            PlanPeriod.month => l.projectRemindMonth,
          }, style: KibuoType.caption),
        ],
      ),
    );
  }
}

String _upper(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

/// « Versements »: each line's date, where it came from, the amount; a
/// line taken back in grey.
class _Payments extends StatelessWidget {
  const _Payments({required this.lines, required this.money});

  final List<ContributionLine> lines;
  final String Function(Money) money;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        children: [
          for (final (i, c) in lines.indexed) ...[
            if (i > 0) const Divider(height: 1, color: KibuoColors.background),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.MMMd(lang).format(c.date),
                          style: KibuoType.rowLabel,
                        ),
                        Text(
                          c.amount.minor < 0
                              ? l.projectTakenBack(c.account)
                              : c.from == null
                              ? c.account
                              : l.projectFromTo(c.from!, c.account),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.amount.minor < 0
                        ? '−${money(Money(-c.amount.minor, c.amount.currency))}'
                        : '+${money(c.amount)}',
                    style: KibuoType.rowLabel
                        .copyWith(
                          color: c.amount.minor < 0
                              ? KibuoColors.inkMuted
                              : KibuoColors.projectInk,
                        )
                        .weight(700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
