import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Opens a sheet of the design system: handle, [title] with ✕, then what
/// [builder] gives, with the sheet's margins.
Future<T?> showKibuoSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: sheetPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: title),
            const SizedBox(height: 12),
            builder(context),
          ],
        ),
      ),
    ),
  );
}

/// A sheet's margins: 16 on the sides, and 24 above the phone's own bar
/// (gestures or buttons), so the last button never sits on the screen's
/// edge (DIRECTION).
EdgeInsets sheetPadding(BuildContext context, {double top = 0}) =>
    EdgeInsets.fromLTRB(
      16,
      top,
      16,
      24 + MediaQuery.viewPaddingOf(context).bottom,
    );

/// The main action at the bottom of a screen: 8 above it, and 24 above
/// the phone's own bar (DIRECTION).
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: child,
    ),
  );
}

/// A sheet's title, with ✕ to close it.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: KibuoType.sheetTitle)),
        SizedBox.square(
          dimension: KibuoTheme.heightTouch,
          child: IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerRight,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(KibuoIcons.x, color: KibuoColors.inkSecondary),
          ),
        ),
      ],
    );
  }
}

/// The title of a tab (Accueil, Opérations, Plus): no back arrow.
class TabTitle extends StatelessWidget {
  const TabTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: KibuoType.tabTitle),
    );
  }
}

/// « Étape 2 sur 4 » and the big title of a first-start screen.
class StepTitle extends StatelessWidget {
  const StepTitle({super.key, required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: KibuoType.sectionTitle.copyWith(color: KibuoColors.accent),
        ),
        Text(title, style: KibuoType.highlight),
      ],
    );
  }
}
