import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The Kibuo keypad for amounts and rates: 1 to 9, the decimal comma (or
/// « 000 » for a currency without cents, PRODUCT), 0 and ← to erase. The
/// same everywhere, so the thumb learns it once.
class KibuoKeypad extends StatelessWidget {
  const KibuoKeypad({
    super.key,
    required this.onKey,
    required this.onDelete,
    this.decimalSeparator = ',',
    this.allowDecimal = true,
    this.onMinus,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final String decimalSeparator;
  final bool allowDecimal;

  /// Holding the decimal key flips the sign, shown by a small « − » in its
  /// corner (canvas SigneD): only where a value may be negative (a balance
  /// with overdraft, PRODUCT).
  final VoidCallback? onMinus;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ...'123456789'.split(''),
      allowDecimal ? decimalSeparator : '000',
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
                child: _key(context, k, minus: k == keys[9] ? onMinus : null),
              ),
          ],
        );
      },
    );
  }

  Widget _key(BuildContext context, String k, {VoidCallback? minus}) {
    final delete = k == '←';
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Haptics.tap();
          if (delete) {
            onDelete();
          } else {
            // The decimal key shows the language's mark (« . » in English)
            // but always types « , », the one the app reads.
            onKey(allowDecimal && k == decimalSeparator ? ',' : k);
          }
        },
        onLongPress: minus == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                minus();
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (minus != null)
              Positioned(
                top: 4,
                right: 10,
                child: Text(
                  '−',
                  style: KibuoType.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation.weight(600)],
                  ),
                ),
              ),
            Center(child: _label(context, k, delete)),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String k, bool delete) {
    return Center(
      child: delete
          ? Icon(
              KibuoIcons.arrowLeft,
              size: 24,
              color: KibuoColors.ink,
              semanticLabel: AppLocalizations.of(context).keypadDelete,
            )
          : Text(k, style: KibuoType.key),
    );
  }
}

/// The keypad on its panel, like a sheet's, with « Terminé » under it: shown
/// at the bottom of an entry while a value is typed (Lancement3).
class KeypadPanel extends StatelessWidget {
  const KeypadPanel({
    super.key,
    required this.keypad,
    required this.done,
    required this.onDone,
  });

  final KibuoKeypad keypad;
  final String done;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: KibuoColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KibuoTheme.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: KibuoColors.barShadow,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: KibuoColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          keypad,
          const SizedBox(height: 8),
          _DarkButton(label: done, onPressed: onDone),
        ],
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.ink,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: KibuoTheme.heightField,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: KibuoType.button.copyWith(color: KibuoColors.surface),
            ),
          ),
        ),
      ),
    );
  }
}

/// Appends key [k] to a typed amount: digits, the decimal comma (once, and
/// only with [decimals] > 0), « 000 »; at most [decimals] after the comma
/// and 12 digits before it.
String typeKey(String typed, String k, {required int decimals}) {
  if (k == ',') {
    if (decimals == 0 || typed.contains(',')) return typed;
    return typed.isEmpty ? '0,' : '$typed,';
  }
  final parts = typed.split(',');
  final add = k == '000' ? (typed.isEmpty ? '' : '000') : k;
  if (parts.length == 2) {
    final room = decimals - parts[1].length;
    return room <= 0
        ? typed
        : '$typed${add.substring(0, add.length.clamp(0, room))}';
  }
  if (parts[0].length + add.length > 12) return typed;
  return typed == '0' ? (add == '000' ? typed : add) : '$typed$add';
}

/// What kibuo's keypad types into. An amount already there when it opens
/// (proposed, or to change) is [selected]: the first key replaces it, « ← »
/// takes its last digit off and keeps the rest, and [keep] (the field
/// touched) lets the keys follow on (PRODUCT, 27 November 2026).
class KeypadText {
  KeypadText(String start) : text = start, selected = start.isNotEmpty;

  String text;

  /// Still the amount the keypad opened on, shown selected.
  bool selected;

  /// Key [k], as [typeKey] says, on a fresh amount while [selected].
  void key(String k, {required int decimals}) {
    text = typeKey(selected ? '' : text, k, decimals: decimals);
    selected = false;
  }

  void delete() {
    selected = false;
    if (text.isNotEmpty) text = text.substring(0, text.length - 1);
  }

  /// The amount kept: the keys follow on.
  void keep() => selected = false;
}

/// Once Kibuo's keypad is laid out, scrolls the field of [key] just enough
/// to sit above it: the keypad takes the bottom of the screen, and nothing
/// else would bring the field back into view.
void revealAboveKeypad(GlobalKey key) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = key.currentContext;
    if (context == null || !context.mounted) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  });
}
