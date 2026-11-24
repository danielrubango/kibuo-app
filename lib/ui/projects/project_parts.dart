import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/projects/projects_screen.dart' show projectIcon;
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// What a project's rhythm says today (PRODUCT: Projets): where it should
/// be, how far ahead or behind, and the part per period, rounded up to
/// the currency's unit. Only a running dated project not yet reached has
/// a rhythm.
class ProjectPace {
  factory ProjectPace.of(ProjectInfo p, DateTime now) {
    final due = p.due;
    if (due == null || !p.running || p.reached) {
      return const ProjectPace._(dated: false, mark: null, gap: 0, per: 0);
    }
    final mark = expectedShare(today: now, start: p.startedOn, due: due);
    return ProjectPace._(
      dated: true,
      mark: mark,
      gap: projectGap(goal: p.goal.minor, saved: p.saved.minor, share: mark),
      per: perPeriod(
        goal: p.goal.minor,
        saved: p.saved.minor,
        today: now,
        due: due,
        period: p.period,
        unit: unitOf(p.goal.currency),
      ),
    );
  }

  const ProjectPace._({
    required this.dated,
    required this.mark,
    required this.gap,
    required this.per,
  });

  final bool dated;

  /// Where it should be today, from 0 to 1.
  final double? mark;

  /// Ahead (positive) or behind (negative), in the minor unit.
  final int gap;

  /// What to set aside per period.
  final int per;

  bool get late => dated && gap < 0;
  bool get ahead => dated && gap > 0;
}

/// One whole unit of [currency] in its minor unit: 100 for the dollar,
/// 1 for the franc.
int unitOf(String currency) {
  final c = currencyOf(currency);
  return c.usesDecimals ? math.pow(10, c.digits).toInt() : 1;
}

/// The project's icon on its tint, rounded at a third.
class ProjectTile extends StatelessWidget {
  const ProjectTile({super.key, required this.icon, this.size = 40});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: KibuoColors.projectTint,
      borderRadius: BorderRadius.circular(size * 0.32),
    ),
    child: Icon(
      projectIcon(icon),
      size: size / 2,
      color: KibuoColors.projectInk,
    ),
  );
}

/// The project's bar, [height] high, and a black mark where it should be
/// today, 8 taller than the bar.
class ProjectBar extends StatelessWidget {
  const ProjectBar({
    super.key,
    required this.share,
    required this.fill,
    this.mark,
    this.height = 8,
  });

  final double share;
  final double? mark;
  final Color fill;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height + 8,
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: KibuoColors.projectTrack,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          Container(
            height: height,
            width: box.maxWidth * share,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          if (mark case final m?)
            Positioned(
              left: (box.maxWidth * m - 1).clamp(0, box.maxWidth - 2),
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: KibuoColors.ink,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// « 9 jours », « 7 semaines », « 4 mois » until [due]; null once past.
String? projectTimeLeft(AppLocalizations l, DateTime now, DateTime due) {
  final days = DateTime.utc(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  if (days <= 0) return null;
  if (days < 14) return l.projectDaysLeft(days);
  if (days < 70) return l.projectWeeksLeft((days / 7).round());
  return l.projectMonthsLeft((days / 30.4375).round());
}

/// « Avant le 1er janv. · 7 semaines », or « Sans date ».
String projectWhen(
  AppLocalizations l,
  String lang,
  ProjectInfo p,
  DateTime now, {
  bool short = true,
}) {
  final due = p.due;
  if (due == null) return l.projectsNoDate;
  final day = (short ? DateFormat.MMMd(lang) : DateFormat.MMMMd(lang)).format(
    due,
  );
  final left = projectTimeLeft(l, now, due);
  return left == null
      ? l.projectsBefore(day)
      : '${l.projectsBefore(day)} · $left';
}

/// « par semaine », « par quinzaine », « par mois ».
String projectPerWord(AppLocalizations l, PlanPeriod period) =>
    switch (period) {
      PlanPeriod.week => l.projectsPerWeek,
      PlanPeriod.fortnight => l.projectsPerFortnight,
      PlanPeriod.month => l.projectsPerMonth,
    };
