// A review screen of the design system, reached from Plus in debug builds
// only, so the owner can check every piece on a real phone. Never shipped:
// its texts are not translated on purpose.
import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/pin_pad.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

class DesignSystemScreen extends StatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  State<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends State<DesignSystemScreen> {
  var _balance = '120';
  var _privacy = true;
  var _fingerprint = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Système de design')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          ..._part('Couleurs', _colors()),
          ..._part('Textes', _type()),
          ..._part('Coins', _radii()),
          ..._part('Boutons', _buttons()),
          ..._part('Champs', _fields()),
          ..._part('Listes et cartes', _lists()),
          ..._part('Feuilles et clavier', _sheets()),
          ..._part('En-têtes', _headers()),
        ],
      ),
    );
  }

  List<Widget> _part(String title, List<Widget> children) => [
    const SizedBox(height: 24),
    Text(title, style: KibuoType.screenTitle),
    const SizedBox(height: 12),
    ...children,
  ];

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: KibuoType.caption.copyWith(color: KibuoColors.inkMuted),
    ),
  );

  List<Widget> _colors() {
    const colors = [
      ('Fond', KibuoColors.background),
      ('Surface', KibuoColors.surface),
      ('Encre', KibuoColors.ink),
      ('Texte secondaire', KibuoColors.inkSecondary),
      ('Discret', KibuoColors.inkMuted),
      ('Ligne', KibuoColors.line),
      ('Ligne forte', KibuoColors.lineStrong),
      ('Piste', KibuoColors.track),
      ('Remplissage', KibuoColors.fill),
      ('Menthe', KibuoColors.mint),
      ('Accent', KibuoColors.accent),
      ('Teinte accent', KibuoColors.accentTint),
      ('Teinte accent forte', KibuoColors.accentTintStrong),
      ('Dette', KibuoColors.debtInk),
      ('Teinte dette', KibuoColors.debtTint),
      ('Projet', KibuoColors.projectInk),
      ('Teinte projet', KibuoColors.projectTint),
      ('Alerte', KibuoColors.warning),
      ('Encre alerte', KibuoColors.warningInk),
      ('Teinte alerte', KibuoColors.warningTint),
      ('Danger', KibuoColors.danger),
      ('Pièce', KibuoColors.coin),
    ];
    return [
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
        children: [
          for (final (name, color) in colors)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        KibuoTheme.radiusTile,
                      ),
                      border: Border.all(color: KibuoColors.line),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: KibuoType.caption.copyWith(color: KibuoColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: KibuoType.caption,
                ),
              ],
            ),
        ],
      ),
      _label('Voile derrière une feuille : encre à 42 %'),
      Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
          color: KibuoColors.mint,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
          color: KibuoColors.scrim,
        ),
      ),
    ];
  }

  List<Widget> _type() {
    final styles = [
      ('Titre d’onglet · 24', KibuoType.tabTitle, 'Plus'),
      ('Titre d’écran · 22', KibuoType.screenTitle, 'Devises'),
      (
        'Titre de feuille · 20',
        KibuoType.sheetTitle,
        'Taux du franc congolais',
      ),
      ('Grand montant · 34', KibuoType.bigAmount, '−14 000 FC'),
      ('Montant ou code · 28', KibuoType.highlight, 'USD'),
      ('Valeur saisie · 26', KibuoType.enteredValue, '2 850'),
      ('Titre de carte · 17', KibuoType.cardTitle, 'Courses du mois'),
      ('Nom d’élément · 16', KibuoType.itemName, 'Franc congolais, CDF'),
      ('Libellé de ligne · 15', KibuoType.rowLabel, 'Verrouillage'),
      ('Texte · 14', KibuoType.body, '1 \$ = 2 800 FC'),
      ('Titre de section · 13', KibuoType.sectionTitle, 'Taux de conversion'),
      (
        'Aide · 13',
        KibuoType.help,
        'Modifier un taux ne change pas les opérations déjà enregistrées.',
      ),
      ('Légende · 12', KibuoType.caption, 'Mis à jour le 3 novembre'),
      ('Bouton · 16', KibuoType.button, 'Enregistrer le taux'),
      ('Touche · 22', KibuoType.key, '1  2  3'),
    ];
    return [
      for (final (name, style, sample) in styles) ...[
        _label(name),
        Text(sample, style: style),
      ],
    ];
  }

  List<Widget> _radii() {
    const radii = [
      (KibuoTheme.radiusPill, 'Pastille'),
      (KibuoTheme.radiusTile, 'Champ'),
      (KibuoTheme.radiusField, 'Touche'),
      (KibuoTheme.radiusCard, 'Carte'),
      (KibuoTheme.radiusFeatured, 'En avant'),
      (KibuoTheme.radiusSheet, 'Feuille'),
    ];
    return [
      Wrap(
        spacing: 8,
        runSpacing: 12,
        children: [
          for (final (r, name) in radii)
            SizedBox(
              width: 104,
              child: Column(
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: KibuoColors.surface,
                      borderRadius: BorderRadius.circular(r),
                      border: Border.all(color: KibuoColors.line, width: 2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$name · ${r.toInt()}', style: KibuoType.caption),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _buttons() {
    void tap() {}
    return [
      _label('Principal'),
      KibuoButton(label: 'Enregistrer le taux', onPressed: tap),
      _label('Principal désactivé'),
      const KibuoButton(label: 'Valider', onPressed: null),
      _label('Secondaire'),
      KibuoButton(label: 'Annuler', onPressed: tap, kind: ButtonKind.secondary),
      _label('Contour'),
      KibuoButton(
        label: 'Repartir de zéro',
        onPressed: tap,
        kind: ButtonKind.outline,
      ),
      _label('Sombre'),
      KibuoButton(label: 'Terminé', onPressed: tap, kind: ButtonKind.dark),
      _label('Danger'),
      KibuoButton(
        label: 'Maintenir pour effacer',
        onPressed: tap,
        kind: ButtonKind.danger,
      ),
      _label('Créer'),
      KibuoButton(
        label: 'Créer un autre type',
        onPressed: tap,
        kind: ButtonKind.create,
      ),
      _label('Actions texte'),
      Wrap(
        children: [
          TextAction(label: 'Modifier', onPressed: tap),
          TextAction(
            label: 'Code oublié ?',
            onPressed: tap,
            color: KibuoColors.inkSecondary,
            underline: true,
          ),
        ],
      ),
    ];
  }

  List<Widget> _fields() {
    return [
      _label('Texte'),
      const KibuoTextField(label: 'Nom du compte', hint: 'Ex. M-Pesa'),
      _label('Recherche'),
      const KibuoTextField(
        label: 'Rechercher une devise',
        hint: 'Nom ou code',
        textCapitalization: TextCapitalization.none,
      ),
      _label('Erreur'),
      const KibuoTextField(
        label: 'Nom du compte',
        hint: 'Ex. M-Pesa',
        error: 'Un compte porte déjà ce nom.',
      ),
      _label('Taux'),
      const ValueField(
        prefix: '1 \$ =',
        value: '2 850',
        unit: 'FC',
        note: 'Avant : 2 800 FC · 3 novembre',
      ),
      _label('Montant d’un formulaire : la devise à droite'),
      ValueField(
        label: 'Solde de départ',
        value: _balance,
        unit: 'USD',
        onUnitTap: () {},
        note: 'Dollar américain. Touchez USD pour changer de devise.',
      ),
      const SizedBox(height: 12),
      KibuoKeypad(
        onKey: (k) => setState(() => _balance = '$_balance$k'),
        onDelete: () => setState(
          () => _balance = _balance.isEmpty
              ? ''
              : _balance.substring(0, _balance.length - 1),
        ),
      ),
      _label('Montant au repos'),
      const ValueField(value: '', unit: 'FC', focused: false),
      _label('Montant d’une dépense'),
      OperationAmountField(
        value: '−5',
        unit: '\$',
        onUnitTap: () {},
        footLabel: 'Retiré du compte',
        footValue: '5,00 \$',
      ),
      _label('Montant d’un revenu'),
      OperationAmountField(
        value: '+250',
        unit: '\$',
        income: true,
        onUnitTap: () {},
        footLabel: 'Ajouté au compte',
        footValue: '250,00 \$',
      ),
      _label('Code à chiffres'),
      const Center(child: PinBoxes(count: 6, firm: 4, filled: 1)),
    ];
  }

  List<Widget> _lists() {
    void tap() {}
    return [
      _label('Carte mise en avant'),
      FeaturedCard(
        label: 'Devise principale',
        value: 'USD',
        action: 'Changer',
        onTap: tap,
      ),
      _label('Une carte par élément'),
      const SectionTitle('Taux de conversion'),
      ItemCard(
        title: 'Franc congolais, CDF',
        lines: const ['1 \$ = 2 800 FC', 'Mis à jour le 3 novembre'],
        action: 'Modifier',
        onTap: tap,
      ),
      const SizedBox(height: 8),
      ItemCard(
        title: 'Euro, EUR',
        lines: const ['1 \$ = 0,92 €', 'Mis à jour le 3 novembre'],
        action: 'Modifier',
        onTap: tap,
      ),
      const SizedBox(height: 12),
      const HelpText(
        'Modifier un taux ne change pas les opérations déjà enregistrées.',
      ),
      _label('Carte de réglages'),
      const SectionTitle('Sécurité'),
      SettingsCard(
        children: [
          SettingsRow(
            label: 'Verrouillage',
            value: 'Code · empreinte',
            onTap: tap,
          ),
          SettingsSwitch(
            label: 'Empreinte',
            value: _fingerprint,
            onChanged: (v) => setState(() => _fingerprint = v),
          ),
          SettingsSwitch(
            label: 'Masquer Kibuo dans les applications récentes',
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v),
          ),
          SettingsRow(
            label: 'Code de récupération',
            value: 'Noté le 12 nov.',
            onTap: tap,
          ),
          SettingsRow(label: 'Retirer le code', danger: true, onTap: tap),
        ],
      ),
      const SizedBox(height: 12),
      const HelpText('Vos données sont chiffrées et restent sur ce téléphone.'),
      _label('Lignes avec icône'),
      SettingsCard(
        children: [
          IconRow(
            icon: KibuoIcons.wallet,
            tint: KibuoColors.accentTint,
            iconColor: KibuoColors.accent,
            label: 'Comptes',
            value: '1 248,50 \$',
            onTap: tap,
          ),
          IconRow(
            icon: KibuoIcons.target,
            tint: KibuoColors.projectTint,
            iconColor: KibuoColors.projectInk,
            label: 'Projets',
            value: '2',
            onTap: tap,
          ),
          IconRow(
            icon: KibuoIcons.handCoins,
            tint: KibuoColors.debtTint,
            iconColor: KibuoColors.debtInk,
            label: 'Dettes et créances',
            value: '6',
            onTap: tap,
          ),
        ],
      ),
    ];
  }

  List<Widget> _sheets() {
    return [
      KibuoButton(
        label: 'Ouvrir la feuille du taux',
        kind: ButtonKind.secondary,
        onPressed: () => showKibuoSheet<void>(
          context,
          title: 'Taux du franc congolais',
          builder: (_) => const _RateDemo(),
        ),
      ),
    ];
  }

  List<Widget> _headers() {
    return [
      _label('Onglet'),
      const TabTitle('Plus'),
      _label('Écran avec retour : en haut de cette page'),
      _label('Premier lancement'),
      const StepTitle(step: 'Étape 2 sur 4', title: 'Votre devise principale'),
    ];
  }
}

class _RateDemo extends StatefulWidget {
  const _RateDemo();

  @override
  State<_RateDemo> createState() => _RateDemoState();
}

class _RateDemoState extends State<_RateDemo> {
  var _value = '2850';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueField(prefix: '1 \$ =', value: _value, unit: 'FC'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Avant : 2 800 FC · 3 novembre',
                  style: KibuoType.help,
                ),
              ),
              Text(
                '+50 FC',
                style: KibuoType.sectionTitle.copyWith(
                  color: KibuoColors.debtInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KibuoKeypad(
          onKey: (k) => setState(() => _value = '$_value$k'),
          onDelete: () => setState(
            () => _value = _value.isEmpty
                ? ''
                : _value.substring(0, _value.length - 1),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Les opérations déjà enregistrées gardent leur taux.',
          style: KibuoType.caption,
        ),
        const SizedBox(height: 12),
        KibuoButton(
          label: 'Enregistrer le taux',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 8),
        KibuoButton(
          label: 'Annuler',
          kind: ButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
