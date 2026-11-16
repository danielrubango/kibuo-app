import 'package:flutter/material.dart';

import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/shell/add_choice.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The « Ajouter » sheet opened by a tap on +. Resolves to the chosen entry,
/// or null when closed.
Future<AddChoice?> showAddSheet(BuildContext context) {
  return showModalBottomSheet<AddChoice>(
    context: context,
    isScrollControlled: true,
    barrierColor: KibuoColors.ink.withValues(alpha: 0.42),
    builder: (context) => const _AddSheet(),
  );
}

class _AddSheet extends StatelessWidget {
  const _AddSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final others = AddChoice.values.skip(1).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).addSheetTitle,
                    style: text.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    KibuoIcons.x,
                    color: KibuoColors.inkSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ExpenseCard(onTap: () => _pick(context, AddChoice.expense)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: [
                for (final choice in others)
                  _ChoiceTile(
                    choice: choice,
                    onTap: () => _pick(context, choice),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pick(BuildContext context, AddChoice choice) {
    Navigator.of(context).pop(choice);
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const choice = AddChoice.expense;
    return Material(
      color: KibuoColors.mint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _IconTile(
                icon: KibuoIcons.arrowDown,
                tint: KibuoColors.surface,
                ink: KibuoColors.ink,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.label(AppLocalizations.of(context)),
                      style: text.titleMedium,
                    ),
                    Text(
                      choice.hint(AppLocalizations.of(context)),
                      style: text.bodyMedium?.copyWith(
                        color: KibuoColors.accentDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(KibuoIcons.caretRight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.choice, required this.onTap});

  final AddChoice choice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _IconTile(icon: choice.icon, tint: choice.tint, ink: choice.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.label(AppLocalizations.of(context)),
                      style: text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      choice.hint(AppLocalizations.of(context)),
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.tint,
    required this.ink,
    this.size = 40,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(icon, size: 20, color: ink),
    );
  }
}
