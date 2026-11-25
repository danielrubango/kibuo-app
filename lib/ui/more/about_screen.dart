import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/app_version.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/brand/kibuo_wordmark.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/more/plus_page.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone's e-mail app on [to]; false when there is none.
typedef WriteMail = Future<bool> Function(String to);

Future<bool> _writeMail(String to) async {
  try {
    return await launchUrl(Uri(scheme: 'mailto', path: to));
  } on Object {
    return false;
  }
}

/// « 25 novembre 2026 » in the app's language.
String _longDate(BuildContext context, String iso) =>
    DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(DateTime.parse(iso));

/// Plus › À propos de kibuo (canvas APropos; PRODUCT, 25 November 2026):
/// the logo and the drawn name, the version and its date, a sentence on
/// kibuo, then the privacy policy, the licences and « Nous écrire ».
/// Conditions d'utilisation and Site web wait for the public site.
class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    this.email = contactEmail,
    this.writeMail = _writeMail,
  });

  /// Where « Nous écrire » writes; no line while it is empty.
  final String email;
  final WriteMail writeMail;

  Future<void> _write(BuildContext context) async {
    final opened = await writeMail(email);
    if (opened || !context.mounted) return;
    showKibuoToast(context, AppLocalizations.of(context).aboutNoMailApp(email));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: Column(
              children: [
                const _Logo(),
                const SizedBox(height: 8),
                const KibuoWordmark(size: 24),
                const SizedBox(height: 8),
                Text(
                  l.aboutVersion(
                    appVersion,
                    _longDate(context, appVersionDate),
                  ),
                  textAlign: TextAlign.center,
                  style: KibuoType.body.copyWith(
                    color: KibuoColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    l.aboutTagline,
                    textAlign: TextAlign.center,
                    style: KibuoType.body.copyWith(
                      height: 20 / 14,
                      color: KibuoColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PlusCard(
            children: [
              PlusRow(
                icon: KibuoIcons.shield,
                label: l.aboutPrivacy,
                detail: l.aboutPrivacyDetail,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrivacyPolicyScreen(email: email),
                  ),
                ),
              ),
              PlusRow(
                icon: KibuoIcons.fileText,
                label: l.aboutLicences,
                detail: l.aboutLicencesDetail,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    // Flutter's list on kibuo's background, not on white.
                    builder: (context) => Theme(
                      data: Theme.of(context)
                          .copyWith(cardColor: KibuoColors.background),
                      child: const LicensePage(
                        applicationName: 'kibuo',
                        applicationVersion: appVersion,
                      ),
                    ),
                  ),
                ),
              ),
              if (email.isNotEmpty)
                PlusRow(
                  icon: KibuoIcons.envelopeSimple,
                  label: l.aboutWrite,
                  detail: email,
                  onTap: () => _write(context),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l.aboutMadeWithCare,
            textAlign: TextAlign.center,
            style: KibuoType.caption.copyWith(color: KibuoColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// The logo on its night square, as the app icon (canvas APropos: 72).
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: KibuoColors.ink,
      borderRadius: BorderRadius.circular(72 * 22 / 96),
    ),
    child: const CustomPaint(painter: KibuoMarkPainter()),
  );
}

/// À propos › Politique de confidentialité: what kibuo keeps, where, and
/// what it does not do, readable without network. The same text is meant
/// for the public site (backlog/site-public.md).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key, this.email = contactEmail});

  final String email;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sections = [
      (l.privacyKeepsTitle, l.privacyKeepsBody),
      (l.privacyWhereTitle, l.privacyWhereBody),
      (l.privacyNothingTitle, l.privacyNothingBody),
      (l.privacyBackupsTitle, l.privacyBackupsBody),
      (l.privacyAndroidTitle, l.privacyAndroidBody),
      (l.privacyDeviceTitle, l.privacyDeviceBody),
      (l.privacyEraseTitle, l.privacyEraseBody),
      if (email.isNotEmpty)
        (l.privacyContactTitle, l.privacyContactBody(email)),
    ];
    final paragraph = KibuoType.body.copyWith(height: 20 / 14);
    return Scaffold(
      appBar: AppBar(title: Text(l.aboutPrivacy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            l.privacyUpdated(_longDate(context, privacyPolicyDate)),
            style: KibuoType.caption,
          ),
          const SizedBox(height: 12),
          Text(l.privacyIntro, style: paragraph),
          for (final (title, body) in sections) ...[
            const SizedBox(height: 20),
            Text(title, style: KibuoType.cardTitle),
            const SizedBox(height: 6),
            Text(body, style: paragraph),
          ],
        ],
      ),
    );
  }
}

/// The day the privacy policy was last changed.
const privacyPolicyDate = '2026-11-25';
