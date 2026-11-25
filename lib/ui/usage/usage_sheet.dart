import 'package:flutter/material.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/icon_tile.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/more/about_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/usage/usage_measure.dart';

/// « Aider à améliorer kibuo ? » (variant B of `MesureUsage-variantes.html`,
/// 25 November 2026): asked once, after the first launch or at the next
/// opening. The ✕, a touch beside or a swipe answer « Non merci », and the
/// sheet never comes back.
Future<void> askUsageConsent(BuildContext context, UsageMeasure measure) async {
  final l = AppLocalizations.of(context);
  final yes = await showKibuoSheet<bool>(
    context,
    title: l.usageTitle,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l.usageIntro, style: KibuoType.help),
        ),
        const SizedBox(height: 12),
        Material(
          color: KibuoColors.surface,
          borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 14, 2),
            child: Column(
              children: [
                _UsageLine(
                  icon: KibuoIcons.check,
                  tint: KibuoColors.accentTint,
                  ink: KibuoColors.accent,
                  title: l.usageSentTitle,
                  text: l.usageSentText,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: KibuoColors.background,
                ),
                _UsageLine(
                  icon: KibuoIcons.x,
                  tint: KibuoColors.dangerTint,
                  ink: KibuoColors.danger,
                  title: l.usageNeverTitle,
                  text: l.usageNeverText,
                ),
              ],
            ),
          ),
        ),
        ActionUnderCard(
          label: l.usageReadPolicy,
          onPressed: () => Navigator.of(sheet).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrivacyPolicyScreen(),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: KibuoButton(
                label: l.usageNo,
                kind: ButtonKind.secondary,
                onPressed: () => Navigator.of(sheet).pop(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KibuoButton(
                label: l.usageYes,
                kind: ButtonKind.mint,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  await measure.answer(yes: yes ?? false);
}

/// « Ce qui part » or « Jamais »: its tile of 36, a title and its line.
class _UsageLine extends StatelessWidget {
  const _UsageLine({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconTile(icon: icon, tint: tint, ink: ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KibuoType.rowLabel),
                Text(text, style: KibuoType.help),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
