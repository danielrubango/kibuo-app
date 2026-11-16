import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/buttons.dart';
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

/// A confirmation before something is removed (PRODUCT, canvas
/// ConfirmArchive): what is concerned, the consequence in one sentence, then
/// the red button; ✕ or a tap outside gives up. True for the red button.
Future<bool> confirmRemoval(
  BuildContext context, {
  required String title,
  required Widget summary,
  required String text,
  required String action,
}) async {
  final sure = await showKibuoSheet<bool>(
    context,
    title: title,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
          ),
          child: summary,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(text, style: KibuoType.help),
        ),
        const SizedBox(height: 24),
        KibuoButton(
          label: action,
          kind: ButtonKind.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return sure ?? false;
}

/// The summary line of [confirmRemoval]: a tile, a name, a line under it.
class RemovalSummary extends StatelessWidget {
  const RemovalSummary({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KibuoType.rowLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation.weight(600)],
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KibuoType.caption,
                ),
            ],
          ),
        ),
        if (trailing != null) Text(trailing!, style: KibuoType.itemName),
      ],
    );
  }
}
