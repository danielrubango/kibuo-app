import 'package:flutter/material.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/share_bar.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// One share among others (canvas ApercuP2, CatB-page): a tile when there
/// is one, the name and the amount, then a bar of the share and its
/// percentage. Touched anywhere, it opens what [onTap] says, without an
/// arrow (owner, 27 November 2026: an arrow at the edge broke the line of
/// the amounts). Its room around comes from [padding], set where it is
/// used.
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
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
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
                      // The name takes what the amount leaves.
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: nameStyle ?? KibuoType.rowLabel,
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

/// A grey tile for a line that is not a category of the lists (« Dettes et
/// créances », « Frais de transfert », the rest folded).
class PlainLineTile extends StatelessWidget {
  const PlainLineTile({super.key, required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: categoryHue(CategoryColor.grey),
      borderRadius: BorderRadius.circular(size * 0.32),
    ),
    child: Icon(icon, size: size * 0.6, color: KibuoColors.ink),
  );
}
