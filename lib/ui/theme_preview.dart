import 'package:flutter/material.dart';

import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Temporary screen that shows the theme on the device until the real
/// screens exist. Its text is not localised on purpose; it goes away with the
/// navigation step.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text('Thème Kibuo', style: text.headlineLarge),
            const SizedBox(height: 2),
            Text('Aperçu des couleurs et des polices', style: text.bodyMedium),
            const SizedBox(height: 16),
            const _AvailableBlock(),
            const SizedBox(height: 12),
            const _MonthCard(),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _SmallCard(
                    title: 'Je dois',
                    amount: '−180,00 \$',
                    color: KibuoColors.debtInk,
                    detail: '3 dettes · 1 en retard',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SmallCard(
                    title: 'On me doit',
                    amount: '+75,00 \$',
                    color: KibuoColors.accent,
                    detail: '2 créances',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Teintes', style: text.titleLarge),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip('Revenu', KibuoColors.accentTint, KibuoColors.accent),
                _Chip('Dette', KibuoColors.debtTint, KibuoColors.debtInk),
                _Chip(
                  'Projet',
                  KibuoColors.projectTint,
                  KibuoColors.projectInk,
                ),
                _Chip('80 %', KibuoColors.warningTint, KibuoColors.warningInk),
                _Chip('En retard', Color(0xFFFBE3DE), KibuoColors.danger),
              ],
            ),
            const SizedBox(height: 20),
            Text('Textes', style: text.titleLarge),
            const SizedBox(height: 8),
            Text('1 234,50 \$', style: text.displayLarge),
            Text('Titre d\'écran', style: text.headlineLarge),
            Text('Ligne de liste', style: text.titleSmall),
            Text('Texte courant, lisible et sobre.', style: text.bodyLarge),
            Text('Texte secondaire, plus discret.', style: text.bodyMedium),
            Text('PETITE ÉTIQUETTE', style: text.labelSmall),
            const SizedBox(height: 20),
            FilledButton(onPressed: () {}, child: const Text('Enregistrer')),
            const SizedBox(height: 8),
            const FilledButton(onPressed: null, child: Text('Grisé')),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Text(
                      'Une feuille, avec sa poignée.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                child: const Text('Ouvrir une feuille ›'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableBlock extends StatelessWidget {
  const _AvailableBlock();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
          decoration: const BoxDecoration(
            color: KibuoColors.mint,
            borderRadius: BorderRadius.all(
              Radius.circular(KibuoTheme.radiusCard),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disponible', style: text.labelLarge),
                    const SizedBox(height: 4),
                    Text('1 234,50 \$', style: text.displayLarge),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: KibuoColors.ink),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(
            color: KibuoColors.accentTintStrong,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Total 1 534,50 \$', style: text.labelMedium),
              ),
              Text('dont projets 300,00 \$ ›', style: text.labelMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: KibuoColors.inkSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Novembre · ce mois-ci', style: text.bodyMedium),
                ),
                const Icon(Icons.chevron_right, color: KibuoColors.inkMuted),
              ],
            ),
            const SizedBox(height: 6),
            Text('+612,00 \$ restants', style: text.headlineMedium),
            const SizedBox(height: 12),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: LinearProgressIndicator(
                value: 0.49,
                minHeight: 10,
                color: KibuoColors.lineStrong,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('49 % dépensés', style: text.bodyMedium)),
                Text('−588,00 sur +1 200,00', style: text.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.detail,
  });

  final String title;
  final String amount;
  final Color color;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title ›', style: text.titleSmall),
            const SizedBox(height: 6),
            Text(amount, style: text.headlineMedium?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(detail, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}
