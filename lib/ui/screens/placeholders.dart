import 'package:flutter/material.dart';

import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/shell/add_choice.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Stand-in for a tab until its real screen is built.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
    this.subtitle,
    this.extra,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String message;

  /// Shown under the placeholder card.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      // Room for the floating bar and its fade.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, KibuoTheme.belowTabBar),
      children: [
        TabHeader(title: TabHeader.text(title), subtitle: subtitle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
            border: Border.all(color: KibuoColors.line),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: KibuoColors.fill,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: KibuoColors.inkSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
        if (extra != null) ...[const SizedBox(height: 16), extra!],
      ],
    );
  }
}

/// Stand-in for an entry screen opened from +. Like every creation screen it
/// has no bottom bar and « Annuler » at the top left.
class EntryPlaceholder extends StatelessWidget {
  const EntryPlaceholder({super.key, required this.choice});

  final AddChoice choice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(title: choice.entryTitle(l), cancel: l.cancel),
            Expanded(child: _body(context, text)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TextTheme text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: choice.tint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(choice.icon, color: choice.ink),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).entryComingLater,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Icons for the empty tabs.
abstract final class PlaceholderIcons {
  static const home = KibuoIcons.house;
  static const operations = KibuoIcons.list;
  static const more = KibuoIcons.squaresFour;
}
