import 'package:flutter/material.dart';
import 'package:kibuo/app_version.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/icon_tile.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/more/plus_summary.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Where a line of Plus leads.
enum PlusEntry {
  accounts,
  budgets,
  projects,
  debts,
  recurrences,
  categories,
  settings,
  backup,
}

/// The Plus tab (canvas Plus, PlusAncienne): « Mes espaces », then
/// Réglages and « Sauvegarde et export », then the version. The card of
/// Aide, À propos and Noter waits for its lines (PRODUCT, 25 November).
class PlusPage extends StatefulWidget {
  const PlusPage({
    super.key,
    required this.load,
    required this.onOpen,
    this.backups,
    this.refresh,
    this.now = DateTime.now,
  });

  final Future<PlusSummary> Function() load;

  /// Opens a line's page; the figures are read again when it closes.
  final Future<void> Function(PlusEntry entry) onOpen;

  /// When the last backup was; no line without it.
  final BackupService? backups;

  /// Rings when the figures may have changed (a save, the tab shown).
  final Listenable? refresh;
  final DateTime Function() now;

  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> {
  PlusSummary? _summary;
  BackupState? _backup;

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
    final summary = await widget.load();
    final backup = await widget.backups?.state();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _backup = backup;
    });
  }

  Future<void> _open(PlusEntry entry) async {
    await widget.onOpen(entry);
    await _load();
  }

  /// « Français · USD · début le 1er · verrouillage » (canvas Plus).
  String _settingsLine(AppLocalizations l, PlusSummary s) {
    final lock = KibuoLock.maybeControllerOf(context);
    final language = switch (Localizations.localeOf(context).languageCode) {
      'en' => 'English',
      _ => 'Français',
    };
    return [
      language,
      s.mainCurrency,
      l.plusMonthStart(monthStartChoice.value),
      if (lock?.hasPin ?? false) l.plusLock,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _summary;
    final backup = _backup;
    final now = widget.now();
    final last = backup?.last;
    final old = backup != null && backup.old(now);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, KibuoTheme.belowTabBar),
      children: [
        TabHeader(title: TabHeader.text(l.tabMore)),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(l.plusSpaces, style: KibuoType.sectionTitle),
        ),
        _PlusCard(
          children: [
            PlusRow(
              icon: KibuoIcons.wallet,
              tint: KibuoColors.accentTintStrong,
              ink: KibuoColors.accent,
              label: l.accountsTitle,
              value: s?.accounts == null ? null : context.money(s!.accounts!),
              onTap: () => _open(PlusEntry.accounts),
            ),
            PlusRow(
              icon: KibuoIcons.chartPieSlice,
              tint: KibuoColors.warningTint,
              ink: KibuoColors.warningInk,
              label: l.budgetsTitle,
              value: s == null ? null : '${s.budgets}',
              onTap: () => _open(PlusEntry.budgets),
            ),
            PlusRow(
              icon: KibuoIcons.target,
              tint: KibuoColors.projectTint,
              ink: KibuoColors.projectInk,
              label: l.projectsTitle,
              value: s == null ? null : '${s.projects}',
              onTap: () => _open(PlusEntry.projects),
            ),
            PlusRow(
              icon: KibuoIcons.arrowsLeftRight,
              tint: KibuoColors.debtTint,
              ink: KibuoColors.debtInk,
              label: l.debtsTitle,
              value: s == null ? null : '${s.debts}',
              onTap: () => _open(PlusEntry.debts),
            ),
            PlusRow(
              icon: KibuoIcons.repeat,
              label: l.recurrencesTitle,
              value: s == null ? null : '${s.recurrences}',
              onTap: () => _open(PlusEntry.recurrences),
            ),
            PlusRow(
              icon: KibuoIcons.tag,
              label: l.categoriesTitle,
              value: s == null ? null : '${s.categories}',
              onTap: () => _open(PlusEntry.categories),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _PlusCard(
          children: [
            PlusRow(
              icon: KibuoIcons.gear,
              label: l.plusSettings,
              detail: s == null ? null : _settingsLine(l, s),
              onTap: () => _open(PlusEntry.settings),
            ),
            if (widget.backups != null)
              PlusRow(
                icon: KibuoIcons.downloadSimple,
                // Old: amber, with its dot (canvas PlusAncienne).
                tint: old
                    ? KibuoColors.warningTint
                    : KibuoColors.accentTintStrong,
                ink: old ? KibuoColors.warningInk : KibuoColors.accent,
                dot: old,
                label: l.moreBackup,
                detail: backup == null
                    ? null
                    : switch (last == null ? null : backupAgeDays(last, now)) {
                        null => l.plusBackupNone,
                        0 => l.plusBackupToday,
                        1 => l.plusBackupYesterday,
                        final d => l.plusBackupDays(d),
                      },
                detailColor: old ? KibuoColors.warningInk : null,
                onTap: () => _open(PlusEntry.backup),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l.plusFooter(appVersion),
          textAlign: TextAlign.center,
          style: KibuoType.caption.copyWith(color: KibuoColors.inkMuted),
        ),
      ],
    );
  }
}

/// A white card of Plus: lines separated by a thin line (canvas Plus).
class _PlusCard extends StatelessWidget {
  const _PlusCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: KibuoColors.surface,
    borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 12,
              endIndent: 14,
              color: KibuoColors.background,
            ),
          children[i],
        ],
      ],
    ),
  );
}

/// A line of Plus (canvas Plus): its tile of 36, the name, a grey line
/// under it or a figure at the right, then ›. [dot] is the amber dot of
/// what asks for attention (PlusAncienne).
class PlusRow extends StatelessWidget {
  const PlusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = KibuoColors.background,
    this.ink = KibuoColors.inkSecondary,
    this.value,
    this.detail,
    this.detailColor,
    this.dot = false,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String label;

  /// At the right: a total, a number.
  final String? value;

  /// Under the name: « Dernière sauvegarde hier ».
  final String? detail;
  final Color? detailColor;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    final value = this.value;
    return InkWell(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 14, 2),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconTile(icon: icon, tint: tint, ink: ink),
                  if (dot)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: KibuoColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KibuoColors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.rowLabel,
                    ),
                    if (detail != null)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.caption.copyWith(color: detailColor),
                      ),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                Text(value, style: KibuoType.caption.copyWith(fontSize: 13)),
              ],
              const SizedBox(width: 6),
              const Icon(
                KibuoIcons.caretRight,
                size: 18,
                color: KibuoColors.lineStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
