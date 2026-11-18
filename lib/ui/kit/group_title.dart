import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The title of a group of a list (DIRECTION: Groupes): grey, « · 3 » in
/// light grey, an optional mark on the left and value on the right, and
/// ˄ ˅ when it folds. It carries 8 above and under its text, so it sits
/// centred in its touch zone and 8 from its first element; with
/// [GroupTitle.before] above it, groups stand [GroupTitle.gap] apart.
class GroupTitle extends StatelessWidget {
  const GroupTitle({
    super.key,
    required this.title,
    this.count,
    this.leading,
    this.trailing,
    this.folded,
    this.onTap,
  });

  /// Between two groups, and between a block and its first group: from
  /// the last element above to the title's text (DIRECTION: Groupes).
  static const gap = 20.0;

  /// The white the title keeps above and under its text.
  static const inner = 8.0;

  /// Put above every group title; with the title's own [inner], groups
  /// stand [gap] apart.
  static const before = gap - inner;

  final String title;

  /// « · 3 », after the title.
  final String? count;

  /// An icon or a coloured dot before the title.
  final Widget? leading;

  /// A total, a count or a few words, at the right.
  final Widget? trailing;

  /// Whether the group is folded; null when it does not fold.
  final bool? folded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final folded = this.folded;
    final count = this.count;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: inner),
      child: Row(
        children: [
          if (leading case final leading?) ...[
            leading,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                text: title,
                children: [
                  if (count != null)
                    TextSpan(
                      text: ' · $count',
                      style: KibuoType.sectionTitle.copyWith(
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation.weight(500)],
                        color: KibuoColors.inkMuted,
                      ),
                    ),
                ],
              ),
              style: KibuoType.sectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing case final trailing?) ...[
            const SizedBox(width: 8),
            trailing,
          ],
          if (folded != null) ...[
            const SizedBox(width: 8),
            Icon(
              folded ? KibuoIcons.caretDown : KibuoIcons.caretUp,
              size: 16,
              color: KibuoColors.accent,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      expanded: folded == null ? null : !folded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: row,
      ),
    );
  }
}

/// The few grey words at the right of a group title (« En retard et du
/// jour », « 3 résultats »).
class GroupNote extends StatelessWidget {
  const GroupNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: KibuoType.sectionTitle.copyWith(
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation.weight(500)],
    ),
  );
}
