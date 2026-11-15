import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The label above a field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: KibuoType.sectionTitle.copyWith(color: KibuoColors.ink),
      ),
    );
  }
}

/// A text field: white, no border at rest, a green border while typing.
class KibuoTextField extends StatelessWidget {
  const KibuoTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.error,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? error;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) FieldLabel(label!),
        TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          style: KibuoType.body.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KibuoType.body.copyWith(
              fontSize: 16,
              color: KibuoColors.inkMuted,
            ),
            filled: true,
            fillColor: KibuoColors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: border(KibuoColors.surface, 0),
            enabledBorder: error == null
                ? border(KibuoColors.surface, 0)
                : border(KibuoColors.danger, 2),
            focusedBorder: border(
              error == null ? KibuoColors.accent : KibuoColors.danger,
              2,
            ),
          ),
        ),
        if (error != null) _ErrorLine(error!),
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Text(
        text,
        style: KibuoType.help.copyWith(color: KibuoColors.danger),
      ),
    );
  }
}

/// The grey pill that names a currency. With [onTap] it shows ˅ and lets the
/// user change it.
class CurrencyPill extends StatelessWidget {
  const CurrencyPill({
    super.key,
    required this.text,
    this.onTap,
    this.background = KibuoColors.background,
    this.foreground = KibuoColors.inkSecondary,
  });

  final String text;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: EdgeInsets.only(left: 12, right: onTap == null ? 12 : 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: KibuoType.itemName.copyWith(
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation.weight(700)],
                  color: foreground,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(KibuoIcons.caretDown, size: 16, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A value typed on the Kibuo keypad (an amount, a rate): the optional
/// [prefix] in grey, the value on the left with the green caret, and the
/// currency in a pill on the right.
class ValueField extends StatelessWidget {
  const ValueField({
    super.key,
    required this.value,
    this.label,
    this.prefix,
    this.placeholder = '0',
    this.unit,
    this.onUnitTap,
    this.focused = true,
    this.onTap,
    this.error,
    this.note,
  });

  final String value;
  final String? label;
  final String? prefix;
  final String placeholder;
  final String? unit;
  final VoidCallback? onUnitTap;
  final bool focused;
  final VoidCallback? onTap;
  final String? error;

  /// A grey line under the field.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final borderColor = error != null
        ? KibuoColors.danger
        : focused
        ? KibuoColors.accent
        : KibuoColors.surface;
    final empty = value.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) FieldLabel(label!),
        GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                if (prefix != null) ...[
                  Text(
                    prefix!,
                    style: KibuoType.body.copyWith(
                      fontSize: 16,
                      color: KibuoColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // The value and its caret hug the left; the pill the right.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            empty ? placeholder : value,
                            maxLines: 1,
                            style: KibuoType.enteredValue.copyWith(
                              color: empty ? KibuoColors.inkMuted : null,
                            ),
                          ),
                        ),
                      ),
                      if (focused) const BlinkingCaret(),
                    ],
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 8),
                  CurrencyPill(text: unit!, onTap: onUnitTap),
                ],
              ],
            ),
          ),
        ),
        if (error != null)
          _ErrorLine(error!)
        else if (note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(note!, style: KibuoType.caption),
          ),
      ],
    );
  }
}

/// The big amount of a new expense or income: tinted by its meaning, the
/// currency pill on the right, and what it does to the account underneath.
class OperationAmountField extends StatelessWidget {
  const OperationAmountField({
    super.key,
    required this.value,
    required this.unit,
    required this.footLabel,
    required this.footValue,
    this.income = false,
    this.onUnitTap,
    this.focused = true,
  });

  final String value;
  final String unit;
  final String footLabel;
  final String footValue;
  final bool income;
  final VoidCallback? onUnitTap;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final tint = income ? KibuoColors.accentTint : KibuoColors.debtTint;
    final line = income
        ? KibuoColors.accentTintStrong
        : const Color(0xFFF2CFB3);
    final ink = income ? KibuoColors.accent : KibuoColors.debtInk;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        border: Border.all(color: line, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value.isEmpty ? '0' : value,
                          style: KibuoType.bigAmount.copyWith(
                            color: value.isEmpty ? KibuoColors.inkMuted : null,
                          ),
                        ),
                      ),
                    ),
                    if (focused) const BlinkingCaret(height: 30),
                  ],
                ),
              ),
              CurrencyPill(
                text: unit,
                onTap: onUnitTap,
                background: line,
                foreground: ink,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: line),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(footLabel, style: KibuoType.body)),
              Text(
                footValue,
                style: KibuoType.buttonSmall.copyWith(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The green caret of a field typed on the Kibuo keypad.
class BlinkingCaret extends StatefulWidget {
  const BlinkingCaret({super.key, this.height = 26});

  final double height;

  @override
  State<BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (context, _) => Opacity(
        opacity: _blink.value < 0.5 ? 1 : 0,
        child: Container(
          width: 2,
          height: widget.height,
          margin: const EdgeInsets.only(left: 3),
          color: KibuoColors.accent,
        ),
      ),
    );
  }
}
