import 'package:flutter/material.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The Kibuo keypad for amounts and rates: 1 to 9, the decimal comma, 0 and
/// ← to erase. The same everywhere, so the thumb learns it once.
class KibuoKeypad extends StatelessWidget {
  const KibuoKeypad({
    super.key,
    required this.onKey,
    required this.onDelete,
    this.decimalSeparator = ',',
    this.allowDecimal = true,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final String decimalSeparator;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ...'123456789'.split(''),
      allowDecimal ? decimalSeparator : '',
      '0',
      '←',
    ];
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final width = (box.maxWidth - 2 * gap) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final k in keys)
              SizedBox(
                width: width,
                height: KibuoTheme.heightKey,
                child: k.isEmpty ? null : _key(context, k),
              ),
          ],
        );
      },
    );
  }

  Widget _key(BuildContext context, String k) {
    final delete = k == '←';
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: delete ? onDelete : () => onKey(k),
        child: Center(
          child: delete
              ? Icon(
                  KibuoIcons.arrowLeft,
                  size: 24,
                  color: KibuoColors.ink,
                  semanticLabel: AppLocalizations.of(context).keypadDelete,
                )
              : Text(k, style: KibuoType.key),
        ),
      ),
    );
  }
}
