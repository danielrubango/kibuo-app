import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';

/// An amount typed on kibuo's keypad in a sheet, in [start]'s currency;
/// above [most], refused and felt, with [cap] saying the most.
Future<Money?> typeAmount(
  BuildContext context, {
  required String title,
  required Money start,
  Money? most,
  String Function(String most)? cap,
}) => showKibuoSheet<Money>(
  context,
  title: title,
  builder: (_) => _AmountSheet(start: start, most: most, cap: cap),
);

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.start, this.most, this.cap});

  final Money start;
  final Money? most;
  final String Function(String most)? cap;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _currency = currencyOf(widget.start.currency);
  late String _typed = typedFrom(widget.start, _currency);

  Money get _amount => typedMoney(_typed, _currency);

  bool get _over => widget.most != null && _amount.minor > widget.most!.minor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueField(
          value: shownTyped(context, _typed),
          unit: _currency.code,
          error: _over && widget.cap != null
              ? widget.cap!(formatMoney(widget.most!, _currency, lang))
              : null,
        ),
        const SizedBox(height: 12),
        KibuoKeypad(
          onKey: (k) {
            final was = _over;
            setState(
              () => _typed = typeKey(
                _typed,
                k,
                decimals: _currency.usesDecimals ? _currency.digits : 0,
              ),
            );
            // Above what is left: refused, and felt.
            if (!was && _over) Haptics.refuse();
          },
          onDelete: () => setState(() {
            if (_typed.isNotEmpty) {
              _typed = _typed.substring(0, _typed.length - 1);
            }
          }),
          allowDecimal: _currency.usesDecimals,
          decimalSeparator: NumberFormat.decimalPattern(lang)
              .symbols
              .DECIMAL_SEP,
        ),
        const SizedBox(height: 12),
        KibuoButton(
          label: l.keypadDone,
          kind: ButtonKind.dark,
          onPressed: _over || _amount.minor <= 0
              ? null
              : () => Navigator.of(context).pop(_amount),
        ),
      ],
    );
  }
}
