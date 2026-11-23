import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/obligations/debts_screen.dart' show debtWord;
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

const _device = MethodChannel('kibuo/device');

/// Android's share menu with [text]: the person picks SMS, WhatsApp…
Future<void> shareText(String text) async {
  try {
    await _device.invokeMethod<bool>('shareText', text);
  } on MissingPluginException {
    // Tests and other platforms: nothing to open.
  } on PlatformException {
    // No app to share with.
  }
}

/// « Réclamer à Patience » (canvas ReclamerR1): who owes how much and how
/// late, the message ready and editable, « Envoyer » through the phone's
/// share menu, « Plus tard ».
Future<void> showClaimSheet(
  BuildContext context,
  DebtLine debt, {
  DateTime Function() now = DateTime.now,
}) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<void>(
    context,
    title: l.debtClaimTitle(debt.person),
    builder: (_) => _ClaimSheet(debt: debt, now: now),
  );
}

class _ClaimSheet extends StatefulWidget {
  const _ClaimSheet({required this.debt, required this.now});

  final DebtLine debt;
  final DateTime Function() now;

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  TextEditingController? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_message != null) return;
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final d = widget.debt;
    final amount = formatMoney(d.left, currencyOf(d.left.currency), lang);
    final due = d.due;
    _message = TextEditingController(
      text: due == null
          ? l.debtClaimMessage(d.person, amount)
          : l.debtClaimMessageDue(
              d.person,
              amount,
              DateFormat.MMMMd(lang).format(due),
            ),
    );
  }

  @override
  void dispose() {
    _message?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final d = widget.debt;
    final amount = formatMoney(d.left, currencyOf(d.left.currency), lang);
    final (state, _) = debtState(d, widget.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: KibuoColors.accentTintStrong,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  d.person.isEmpty ? '?' : d.person[0].toUpperCase(),
                  style: KibuoType.cardTitle.copyWith(
                    color: KibuoColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.debtClaimOwes(d.person, amount),
                      style: KibuoType.rowLabel.weight(600),
                    ),
                    if (state == DebtState.late || state == DebtState.today)
                      Text(
                        debtWord(l, d, widget.now()),
                        style: KibuoType.caption
                            .copyWith(color: KibuoColors.danger)
                            .weight(600),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KibuoTextField(
          label: l.debtClaimMessageLabel,
          controller: _message,
          lines: 6,
        ),
        const SizedBox(height: 16),
        KibuoButton(
          label: l.debtClaimSend,
          onPressed: () async {
            await shareText(_message!.text);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 8),
        KibuoButton(
          label: l.debtLater,
          kind: ButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
