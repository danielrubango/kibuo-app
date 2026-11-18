import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Taux de conversion »: the small grey title above a card.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: KibuoType.sectionTitle),
    );
  }
}

/// The grey explanation under a card.
class HelpText extends StatelessWidget {
  const HelpText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: KibuoType.help.copyWith(color: color)),
    );
  }
}

/// A white card with the card corners.
class KibuoCard extends StatelessWidget {
  const KibuoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// The mint card that puts one value forward: « Devise principale · USD ».
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.label,
    required this.value,
    this.action,
    this.onTap,
  });

  final String label;
  final String value;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.mint,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: KibuoType.body.copyWith(
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation.weight(500)],
                      ),
                    ),
                    Text(value, style: KibuoType.highlight),
                  ],
                ),
              ),
              if (action != null) Text(action!, style: KibuoType.buttonSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card per thing the user manages (a currency, an account): its name in
/// bold, a line or two under it, and an action on the right.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.title,
    this.lines = const [],
    this.action,
    this.onTap,
    this.actionColor = KibuoColors.accent,
    this.onAction,
    this.struck = false,
  });

  final String title;

  /// The first line in the body style, the next ones in grey.
  final List<String> lines;
  final String? action;
  final VoidCallback? onTap;
  final Color actionColor;

  /// Makes the action its own target, apart from [onTap].
  final VoidCallback? onAction;

  /// Title and lines struck through: about to go.
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final line = struck ? TextDecoration.lineThrough : null;
    return KibuoCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KibuoType.itemName.copyWith(decoration: line),
                ),
                for (var i = 0; i < lines.length; i++)
                  Text(
                    lines[i],
                    style:
                        (i == 0
                                ? KibuoType.body
                                : KibuoType.help.copyWith(height: 1.4))
                            .copyWith(decoration: line),
                  ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            if (onAction == null)
              Text(
                action!,
                style: KibuoType.buttonSmall.copyWith(
                  fontSize: 14,
                  color: actionColor,
                ),
              )
            else
              TextAction(
                label: action!,
                color: actionColor,
                onPressed: onAction,
              ),
          ],
        ],
      ),
    );
  }
}

/// A white card of settings rows, separated by thin lines.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: KibuoColors.track,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A settings row: label, its current value in grey, and ›.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  final String label;
  final String? value;

  /// Null greys the row out.
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: KibuoType.rowLabel.copyWith(
                    color: onTap == null
                        ? KibuoColors.inkMuted
                        : danger
                        ? KibuoColors.danger
                        : null,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                Text(value!, style: KibuoType.caption.copyWith(fontSize: 13)),
              ],
              if (!danger)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    KibuoIcons.caretRight,
                    size: 16,
                    color: KibuoColors.inkMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with a switch at its right (PRODUCT: touching the whole row
/// flips it, as everywhere on Android).
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.child,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 8, 8),
  });

  /// What the switch is about, at the left.
  final Widget child;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return MergeSemantics(
      child: InkWell(
        onTap: change == null ? null : () => change(!value),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Expanded(child: child),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// A settings row with a switch, and an optional line under its label.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.help,
  });

  final String label;
  final String? help;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final help = this.help;
    return SwitchRow(
      value: value,
      onChanged: onChanged,
      padding: EdgeInsets.fromLTRB(
        16,
        help == null ? 4 : 8,
        8,
        help == null ? 4 : 8,
      ),
      child: help == null
          ? Text(label, style: KibuoType.rowLabel)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KibuoType.rowLabel),
                Text(help, style: KibuoType.caption),
              ],
            ),
    );
  }
}

/// A row with a tinted icon on the left: the Plus page.
class IconRow extends StatelessWidget {
  const IconRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: KibuoType.rowLabel)),
            if (value != null)
              Text(value!, style: KibuoType.caption.copyWith(fontSize: 13)),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                KibuoIcons.caretRight,
                size: 16,
                color: KibuoColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One choice of a sheet: its name, a line under it, and a check when it
/// is the one (Affichage des comptes, Montants longs).
class CheckChoice extends StatelessWidget {
  const CheckChoice({
    super.key,
    required this.label,
    required this.help,
    required this.on,
    required this.onTap,
  });

  final String label;
  final String help;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: on,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: KibuoType.rowLabel),
                    Text(help, style: KibuoType.caption),
                  ],
                ),
              ),
              if (on) const Icon(KibuoIcons.check, color: KibuoColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// One choice of a display sheet (DIRECTION: feuille d'affichage; canvas
/// BudgetsAffichage): its icon in a tile that turns green when the choice
/// is on, the name, one line under it, and a round mark at the right.
class DisplayChoice extends StatelessWidget {
  const DisplayChoice({
    super.key,
    required this.icon,
    required this.label,
    required this.help,
    required this.on,
    required this.onTap,
    this.helpLines = 1,
  });

  final IconData icon;
  final String label;
  final String help;
  final bool on;
  final VoidCallback onTap;

  /// One line in a sheet; a settings page gives the whole sentence.
  final int? helpLines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: on,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: on
                        ? KibuoColors.accentTintStrong
                        : KibuoColors.background,
                    borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: on ? KibuoColors.accent : KibuoColors.inkSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: KibuoType.rowLabel),
                      const SizedBox(height: 2),
                      Text(
                        help,
                        maxLines: helpLines,
                        overflow: helpLines == null
                            ? null
                            : TextOverflow.ellipsis,
                        style: KibuoType.caption.copyWith(height: 16 / 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: on ? KibuoColors.accent : KibuoColors.line,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: on
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: KibuoColors.accent,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
