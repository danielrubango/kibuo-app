import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The link at the end of a card's last line (« Mettre de côté › »,
/// « Détails › »): 13, bold, in green, its touch area 44 high without
/// pushing the card's bottom margin.
class CardLink extends StatelessWidget {
  const CardLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: () {
      Haptics.tap();
      onTap();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label ›',
        style: KibuoType.caption
            .copyWith(fontSize: 13, color: KibuoColors.accent)
            .weight(700),
      ),
    ),
  );
}
