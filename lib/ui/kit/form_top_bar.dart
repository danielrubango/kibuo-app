import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The top of a creation screen (DIRECTION): « Annuler » on the left, the
/// title in the middle, no bottom bar.
class FormTopBar extends StatelessWidget {
  const FormTopBar({super.key, required this.title, required this.cancel});

  final String title;
  final String cancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextAction(
                label: cancel,
                color: KibuoColors.inkSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: KibuoType.button,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 96),
        ],
      ),
    );
  }
}
