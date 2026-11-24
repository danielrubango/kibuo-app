import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A row of a sheet's card (canvas RembourserV3, ProjetP1): the label in
/// grey on the left, « value › » in bold on the right, 44 high. Without
/// [onTap], the value stands alone, no caret.
class ValueRow extends StatelessWidget {
  const ValueRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.color,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(
            label,
            style: KibuoType.body.copyWith(color: KibuoColors.inkSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              onTap == null ? value : '$value ›',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KibuoType.body
                  .copyWith(color: color ?? KibuoColors.ink)
                  .weight(700),
            ),
          ),
        ],
      ),
    ),
  );
}
