import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/empty_card.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/status_pill.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/projects/new_project_screen.dart';
import 'package:kibuo/ui/projects/project_money.dart';
import 'package:kibuo/ui/projects/project_parts.dart';
import 'package:kibuo/ui/projects/project_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// The project's icon, from its name.
IconData projectIcon(String name) =>
    _projectOnly[name] ?? categoryIcons[name] ?? KibuoIcons.target;

/// Icons only projects take; the others are categories' own.
const _projectOnly = <String, IconData>{
  'heart': KibuoIcons.heart,
  'deviceMobile': KibuoIcons.deviceMobile,
  'plant': KibuoIcons.plant,
  'star': KibuoIcons.star,
  'target': KibuoIcons.target,
};

/// Plus › « Projets » (canvas Projets): what is set aside on the total of
/// the goals, then a card per project, the finished ones folded at the
/// bottom, then « Nouveau projet ».
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({
    super.key,
    required this.data,
    required this.projects,
    this.now = DateTime.now,
    this.onChanged,
  });

  final EntryData data;
  final ProjectRepository projects;
  final DateTime Function() now;

  /// A project was made or its money moved: the home's available amount
  /// changes.
  final VoidCallback? onChanged;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectInfo>? _list;
  String? _main;
  Map<String, ExchangeRate> _rates = const {};
  bool _endedShown = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.projects.projects();
    final main = await widget.data.currencies.primaryCurrency();
    final rates = <String, ExchangeRate>{};
    if (main != null) {
      for (final code in {for (final p in list) p.goal.currency}) {
        if (code == main) continue;
        final info = await widget.data.currencies.latestRate(code, main);
        if (info != null) rates[code] = info.rate;
      }
    }
    if (!mounted) return;
    setState(() {
      _list = list;
      _main = main;
      _rates = rates;
    });
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  String _money(Money m) => formatMoney(m, currencyOf(m.currency), _lang);

  int _inMain(Money m) {
    final main = _main;
    if (main == null || m.currency == main) return m.minor;
    final rate = _rates[m.currency];
    return rate == null ? 0 : rate.convert(m, to: currencyOf(main)).minor;
  }

  Future<void> _add() async {
    final made = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NewProjectScreen(
          data: widget.data,
          projects: widget.projects,
          now: widget.now,
        ),
      ),
    );
    if (made != true) return;
    widget.onChanged?.call();
    await _load();
  }

  Future<void> _open(ProjectInfo p) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProjectScreen(
          data: widget.data,
          projects: widget.projects,
          id: p.id,
          now: widget.now,
          onChanged: widget.onChanged,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _putAside(ProjectInfo p) async {
    await putAsideFlow(
      context,
      data: widget.data,
      projects: widget.projects,
      project: p,
      now: widget.now,
    );
    widget.onChanged?.call();
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = _list;
    final running = [
      for (final p in list ?? const <ProjectInfo>[])
        if (p.running) p,
    ];
    final ended = [
      for (final p in list ?? const <ProjectInfo>[])
        if (!p.running) p,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.projectsTitle)),
      body: list == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                if (running.isEmpty && ended.isEmpty)
                  EmptyCard(
                    icon: KibuoIcons.target,
                    title: l.projectsEmpty,
                    help: l.projectsEmptyHelp,
                  )
                else if (running.isNotEmpty) ...[
                  _summary(l, running),
                  if (running.any((p) => p.due != null)) ...[
                    const SizedBox(height: 14),
                    _Legend(text: l.projectsMarkLegend),
                  ],
                  for (final p in running) ...[
                    const SizedBox(height: 14),
                    _ProjectCard(
                      project: p,
                      now: widget.now(),
                      money: _money,
                      onOpen: () => _open(p),
                      onPutAside: () => _putAside(p),
                    ),
                  ],
                ],
                if (ended.isNotEmpty) ...[
                  const SizedBox(height: GroupTitle.before),
                  GroupTitle(
                    title: l.projectsEnded,
                    count: '${ended.length}',
                    folded: !_endedShown,
                    onTap: () => setState(() => _endedShown = !_endedShown),
                  ),
                  if (_endedShown)
                    for (final p in ended) ...[
                      const SizedBox(height: 8),
                      _ProjectCard(
                        project: p,
                        now: widget.now(),
                        money: _money,
                        onOpen: () => _open(p),
                        onPutAside: () => _putAside(p),
                      ),
                    ],
                ],
                const SizedBox(height: 16),
                KibuoButton(
                  label: l.projectsNew,
                  kind: ButtonKind.create,
                  icon: KibuoIcons.plusBold,
                  onPressed: _add,
                ),
              ],
            ),
    );
  }

  /// « Mis de côté · 3 projets », the amount on the goals, the blue bar,
  /// the share and what is left to set aside.
  Widget _summary(AppLocalizations l, List<ProjectInfo> running) {
    final main = _main ?? running.first.goal.currency;
    final saved = running.fold<int>(0, (s, p) => s + _inMain(p.saved));
    final goal = running.fold<int>(0, (s, p) => s + _inMain(p.goal));
    final share = goal <= 0 ? 0.0 : (saved / goal).clamp(0, 1).toDouble();
    final left = goal - saved < 0 ? 0 : goal - saved;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.projectsSaved(running.length),
            style: KibuoType.body.copyWith(color: KibuoColors.inkSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(
                _money(Money(saved, main)),
                style: KibuoType.bigAmount.copyWith(height: 40 / 34),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l.projectsOf(_money(Money(goal, main))),
                  style: KibuoType.body.copyWith(
                    fontSize: 15,
                    color: KibuoColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 10,
              color: KibuoColors.projectLine,
              backgroundColor: KibuoColors.projectTrack,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${(share * 100).round()} %',
                      style: const TextStyle(color: KibuoColors.ink)
                          .weight(700),
                    ),
                    TextSpan(text: ' ${l.projectsOfTotal}'),
                  ],
                ),
                style: KibuoType.body.copyWith(
                  fontSize: 13,
                  color: KibuoColors.inkSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.projectsLeft(_money(Money(left, main))),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KibuoType.body.copyWith(
                    fontSize: 13,
                    color: KibuoColors.inkSecondary,
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

/// « | Où vous devriez en être aujourd'hui pour tenir la date ».
class _Legend extends StatelessWidget {
  const _Legend({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        Container(
          width: 2,
          height: 12,
          decoration: BoxDecoration(
            color: KibuoColors.ink,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: KibuoType.caption)),
      ],
    ),
  );
}

/// A project's card (canvas Projets): its tile, name and « Avant le 1er
/// janv. · compte », « En retard » if it is; what is set aside on the goal
/// and the share; the bar with its mark; ahead or behind and the amount
/// per period, or « À votre rythme », then « Mettre de côté › ». Touched,
/// it opens the project's card.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.now,
    required this.money,
    required this.onOpen,
    required this.onPutAside,
  });

  final ProjectInfo project;
  final DateTime now;
  final String Function(Money) money;
  final VoidCallback onOpen;
  final VoidCallback onPutAside;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = project;
    final due = p.due;
    final pace = ProjectPace.of(p, now);
    final when = due == null
        ? l.projectsNoDate
        : l.projectsBefore(DateFormat.MMMd(lang).format(due));
    final periodWord = switch (p.period) {
      PlanPeriod.week => l.projectsPerWeek,
      PlanPeriod.fortnight => l.projectsPerFortnight,
      PlanPeriod.month => l.projectsPerMonth,
    };
    // « 27 $ de retard · 94 $ par mois »: the gap in bold (canvas Projets).
    final lead = !pace.dated
        ? null
        : pace.late
        ? l.projectsBehind(money(Money(-pace.gap, p.goal.currency)))
        : pace.ahead
        ? l.projectsAhead(money(Money(pace.gap, p.goal.currency)))
        : l.projectsOnTrack;
    final rest = !p.running
        ? (p.ending == 'spent' ? l.projectsEndedSpent : l.projectsEndedReleased)
        : p.reached
        ? l.projectsReached
        : pace.dated
        ? ' · ${money(Money(pace.per, p.goal.currency))} $periodWord'
        : l.projectsOwnPace;
    final restColor = !p.running || !pace.dated
        ? KibuoColors.inkSecondary
        : pace.late
        ? KibuoColors.danger
        : KibuoColors.accent;
    final canAdd = p.running && !p.reached;
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        onTap: () {
          Haptics.tap();
          onOpen();
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, canAdd ? 4 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ProjectTile(icon: p.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.rowLabel.weight(600),
                        ),
                        Text(
                          '$when · ${p.account}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.caption,
                        ),
                      ],
                    ),
                  ),
                  if (pace.late)
                    StatusPill(
                      text: l.projectsLate,
                      ink: KibuoColors.danger,
                      tint: KibuoColors.dangerTint,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    money(p.saved),
                    style: KibuoType.cardTitle.copyWith(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.projectsOf(money(p.goal)),
                      style: KibuoType.body.copyWith(
                        fontSize: 13,
                        color: KibuoColors.inkSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${(p.share * 100).round()} %',
                    style: KibuoType.body
                        .copyWith(
                          fontSize: 13,
                          color: pace.late
                              ? KibuoColors.danger
                              : KibuoColors.projectInk,
                        )
                        .weight(700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ProjectBar(
                share: p.share,
                mark: pace.mark,
                fill: pace.late ? KibuoColors.danger : KibuoColors.projectLine,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (lead != null)
                            TextSpan(
                              text: lead,
                              style: const TextStyle().weight(700),
                            ),
                          TextSpan(text: rest),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.caption.copyWith(color: restColor),
                    ),
                  ),
                  if (canAdd)
                    TextAction(
                      label: '${l.projectPutAside} ›',
                      onPressed: onPutAside,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
