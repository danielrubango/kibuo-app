import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// One ready amount: what it is, and what it means (« ce qui manque »).
class QuickAmount<T> {
  const QuickAmount({
    required this.value,
    required this.amount,
    required this.label,
  });

  final T value;
  final String amount;
  final String label;
}

/// Ready amounts side by side (canvas ProjetP1): the amount in bold, its
/// meaning under it; the chosen one in ink. Always three places wide, so
/// one or two keep the size of three.
class QuickAmounts<T> extends StatelessWidget {
  const QuickAmounts({
    super.key,
    required this.items,
    required this.selected,
    required this.onPick,
  });

  final List<QuickAmount<T>> items;
  final T? selected;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: i < items.length
                ? _Chip(
                    item: items[i],
                    on: items[i].value == selected,
                    onTap: () {
                      Haptics.tap();
                      onPick(items[i].value);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _Chip<T> extends StatelessWidget {
  const _Chip({required this.item, required this.on, required this.onTap});

  final QuickAmount<T> item;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: on,
    button: true,
    child: Material(
      color: on ? KibuoColors.ink : KibuoColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KibuoType.body
                    .copyWith(
                      fontSize: 15,
                      color: on ? KibuoColors.surface : KibuoColors.ink,
                    )
                    .weight(700),
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KibuoType.caption.copyWith(
                  fontSize: 11,
                  color: on ? KibuoColors.line : KibuoColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
