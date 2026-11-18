import 'package:flutter/material.dart';

import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/shell/add_choice.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// One « Refaire » card (canvas PlusBtnB1): the label, the amount in its
/// type's colour, the account and category; [value] comes back when
/// touched.
class RedoCard<T> {
  const RedoCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String amount;
  final Color color;
  final String subtitle;
  final T value;
}

/// The « Ajouter » sheet opened by a tap on +. Resolves to the chosen
/// [AddChoice], to the value of a « Refaire » card, or null when closed.
Future<Object?> showAddSheet(
  BuildContext context, {
  Future<List<RedoCard<Object>>>? redo,
}) {
  return showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    barrierColor: KibuoColors.ink.withValues(alpha: 0.42),
    builder: (context) => _AddSheet(redo: redo),
  );
}

class _AddSheet extends StatelessWidget {
  const _AddSheet({required this.redo});

  /// Loaded while the sheet is already open: the + answers at once.
  final Future<List<RedoCard<Object>>>? redo;

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
            // Two by two, 64 high whatever the screen's width (canvas
            // PlusBtnB1).
            for (var i = 0; i < others.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                children: [
                  for (final (j, choice) in others.skip(i).take(2).indexed) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _ChoiceTile(
                        choice: choice,
                        onTap: () => _pick(context, choice),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            FutureBuilder(
              future: redo,
              builder: (context, snap) => _redoSection(context, snap.data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _redoSection(BuildContext context, List<RedoCard<Object>>? redo) {
    if (redo == null || redo.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            AppLocalizations.of(context).addRedo,
            style: KibuoType.sectionTitle,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: redo.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _RedoTile(
              card: redo[i],
              onTap: () => Navigator.of(context).pop(redo[i].value),
            ),
          ),
        ),
      ],
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
    const choice = AddChoice.expense;
    return Material(
      color: KibuoColors.mint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          // 72 high (canvas PlusBtnB1).
          padding: const EdgeInsets.all(14),
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
                      style: KibuoType.itemName.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation.weight(700)],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      choice.hint(AppLocalizations.of(context)),
                      style: KibuoType.help.copyWith(
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
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _IconTile(
                  icon: choice.icon,
                  tint: choice.tint,
                  ink: choice.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.label(AppLocalizations.of(context)),
                        style: KibuoType.rowLabel.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        choice.hint(AppLocalizations.of(context)),
                        style: KibuoType.caption,
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

class _RedoTile extends StatelessWidget {
  const _RedoTile({required this.card, required this.onTap});

  final RedoCard<Object> card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        onTap: onTap,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KibuoType.rowLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation.weight(600)],
                ),
              ),
              Text(
                card.amount,
                maxLines: 1,
                style: KibuoType.caption.copyWith(
                  color: card.color,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation.weight(700)],
                ),
              ),
              Text(
                card.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KibuoType.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
