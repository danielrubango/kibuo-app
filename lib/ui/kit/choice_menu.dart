import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A filter chip of a list (canvas ListeOperations): 44 high, white, its
/// label and a caret; black with white text once something is chosen; a
/// green outline while its menu is open (DIRECTION).
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.open = false,
  });

  final String label;

  /// Something is chosen: the chip turns black.
  final bool active;

  /// Its menu is open.
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = active
        ? (KibuoColors.ink, KibuoColors.surface)
        : (KibuoColors.surface, KibuoColors.ink);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        side: open
            ? const BorderSide(color: KibuoColors.accent, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        onTap: onTap,
        child: Container(
          height: KibuoTheme.heightTouch,
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: KibuoType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation.weight(600)],
                  color: foreground,
                ),
              ),
              const SizedBox(width: 6),
              Icon(KibuoIcons.caretDown, size: 16, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

/// The panel a filter chip opens (canvas ListeFiltreOuvert): white, 16
/// round, 6 inside, its rows scrolling when they pass [maxHeight].
class ChoiceMenu extends StatelessWidget {
  const ChoiceMenu({
    super.key,
    required this.children,
    this.width = 210,
    this.maxHeight = 300,
  });

  final List<Widget> children;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x380E1320),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// One choice of a filter (canvas ListeFiltreOuvert): its name, its number
/// of operations, then an end column 18 wide where a green check (chosen)
/// or a grey dot sits centred, so the numbers always line up. Chosen: a
/// mint background. Nothing to show and not chosen: greyed, not tappable.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.divided = false,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  /// A thin line above: the first choice after « Tous ».
  final bool divided;

  bool get _off => count == 0 && !selected;

  @override
  Widget build(BuildContext context) {
    final row = Material(
      color: selected ? KibuoColors.accentTint : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _off ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KibuoTheme.heightTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.rowLabel.copyWith(
                      color: _off ? KibuoColors.lineStrong : KibuoColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: KibuoType.sectionTitle.copyWith(
                    color: _off ? KibuoColors.lineStrong : KibuoColors.inkMuted,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox.square(
                  key: const ValueKey('choice-end'),
                  dimension: 18,
                  child: Center(
                    child: selected
                        ? const Icon(
                            KibuoIcons.check,
                            size: 16,
                            color: KibuoColors.accent,
                          )
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: KibuoColors.line,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      enabled: !_off,
      child: divided ? _Divided(child: row) : row,
    );
  }
}

/// « Dépenses », « Revenus »: a group's title inside a filter's choices.
class ChoiceGroupTitle extends StatelessWidget {
  const ChoiceGroupTitle(this.text, {super.key, this.divided = false});

  final String text;

  /// A thin line above: the first group after « Tous ».
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      child: Text(
        text,
        style: KibuoType.caption.copyWith(
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation.weight(600)],
          color: KibuoColors.inkMuted,
        ),
      ),
    );
    return divided ? _Divided(child: title) : title;
  }
}

/// « Afficher les 12 autres »: the last line of a short menu, opening the
/// whole list.
class ChoiceMoreRow extends StatelessWidget {
  const ChoiceMoreRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Divided(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: KibuoTheme.heightTouch),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: KibuoType.body.copyWith(
              fontWeight: FontWeight.w600,
              fontVariations: const [FontVariation.weight(600)],
              color: KibuoColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _Divided extends StatelessWidget {
  const _Divided({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KibuoColors.background)),
      ),
      child: child,
    );
  }
}
