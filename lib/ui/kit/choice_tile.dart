import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A large choice of the first launch (canvas Lancement1, Lancement2):
/// white, 60 high, 16 round, a green 2 border once chosen; the label, and
/// on the right an optional code.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.chosen,
    required this.onTap,
    this.code,
  });

  final String label;
  final bool chosen;
  final VoidCallback onTap;

  /// « USD », in the display font.
  final String? code;

  @override
  Widget build(BuildContext context) {
    final code = this.code;
    return Semantics(
      selected: chosen,
      button: true,
      child: Material(
        color: KibuoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
          side: BorderSide(
            color: chosen ? KibuoColors.accent : KibuoColors.surface,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Haptics.tap();
            onTap();
          },
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.rowLabel.copyWith(fontSize: 16),
                  ),
                ),
                if (code != null)
                  Text(code, style: KibuoType.cardTitle.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
