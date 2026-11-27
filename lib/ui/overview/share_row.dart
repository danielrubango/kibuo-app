import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/share_bar.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Where a row that opens something shows its arrow.
enum ShareArrow {
  /// No arrow: the whole row is touched.
  none,

  /// A small arrow just after the name.
  afterName,

  /// In a column of its own at the right edge (canvas ApercuP2).
  end,
}

/// One share among others (canvas ApercuP2, CatB-page): a tile when there
/// is one, the name and the amount, then a bar of the share and its
/// percentage. Touched, it opens what [onTap] says. Its room around comes
/// from [padding], set where it is used.
class ShareRow extends StatelessWidget {
  const ShareRow({
    super.key,
    required this.name,
    required this.amount,
    required this.percent,
    required this.bar,
    required this.color,
    this.leading,
    this.nameStyle,
    this.onTap,
    this.arrow = ShareArrow.none,
    this.arrowIcon = KibuoIcons.caretRight,
    this.padding = EdgeInsets.zero,
    this.minHeight = 0,
  });

  final String name;
  final String amount;

  /// The share, written (« 48 »).
  final int percent;

  /// The bar's length, the biggest share's being 1.
  final double bar;
  final Color color;
  final Widget? leading;

  /// The name's style; a row's label by default.
  final TextStyle? nameStyle;
  final VoidCallback? onTap;
  final ShareArrow arrow;

  /// The arrow drawn: right for what opens a page, down or up for what
  /// unfolds in place.
  final IconData arrowIcon;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    final arrowShown = onTap != null ? arrow : ShareArrow.none;
    final icon = Icon(arrowIcon, size: 16, color: KibuoColors.inkSecondary);
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // The name takes what the amount leaves; the arrow
                      // follows it closely.
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: nameStyle ?? KibuoType.rowLabel,
                              ),
                            ),
                            if (arrowShown == ShareArrow.afterName) ...[
                              const SizedBox(width: 2),
                              icon,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amount,
                        style: KibuoType.itemName.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ShareBar(share: bar, color: color),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$percent %',
                          textAlign: TextAlign.end,
                          style: KibuoType.caption.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The column stays on every row, so the amounts line up.
            if (arrow == ShareArrow.end)
              SizedBox(
                width: 26,
                child: onTap == null ? null : Center(child: icon),
              ),
          ],
        ),
      ),
    );
    return onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
            child: row,
          );
  }
}
