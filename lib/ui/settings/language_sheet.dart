import 'package:flutter/material.dart';
import 'package:kibuo/data/first_launch_store.dart';
import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/usage/usage_measure.dart';

/// Makes [code] kibuo's language at once (PRODUCT): Android 13 and more
/// keep it as the app's own language, and kibuo follows; older ones, kibuo
/// keeps it. The first launch and Réglages › Langue both choose with it.
Future<void> chooseAppLanguage(FirstLaunchStore store, String code) async {
  appLanguageChoice.value = Locale(code);
  final android = await setAndroidAppLanguage(code);
  await store.setLanguage(android ? null : code);
}

/// Réglages › Langue (canvas ReglageLangue): each language in its own
/// name, the current one checked; touching one chooses it and closes.
Future<void> showLanguageSheet(
  BuildContext context,
  FirstLaunchStore store,
) async {
  final l = AppLocalizations.of(context);
  final current = Localizations.localeOf(context).languageCode;
  final picked = await showKibuoSheet<String>(
    context,
    title: l.settingsLanguage,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          children: [
            for (final (code, name, help) in [
              ('fr', 'Français', l.languageFrenchIn),
              ('en', 'English', l.languageEnglishIn),
            ])
              CheckChoice(
                label: name,
                help: help,
                on: code == current,
                onTap: () => Navigator.of(context).pop(code),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l.languageHelp, style: KibuoType.caption),
        ),
      ],
    ),
  );
  if (picked != null && picked != current) {
    await chooseAppLanguage(store, picked);
    usage.track(UsageEvent.language(picked));
  }
}
