# Système de design de kibuo

De quoi dessiner et coder un écran nouveau qui ressemble à kibuo, sans le canvas. Les **valeurs** viennent du code : en cas de doute, le code fait foi (`lib/ui/theme/`, `lib/ui/kit/`). Les **règles d'écran et les décisions** (où se place quoi, pourquoi, quand validé) sont dans [DIRECTION.md](DIRECTION.md). Les planches sont dans [boards/](boards/) ; la page « Système de design » du canvas y correspond (`DSCouleurs`, `DSTextes`, `DSEspaces`, `DSChamps`, `DSBoutons`, `DSListes`, `DSFeuilles`, `DSPolices`).

Thème clair seulement ; le sombre est au [backlog](../backlog/theme-sombre.md).

## Couleurs

`lib/ui/theme/kibuo_colors.dart`, classe `KibuoColors`. Chaque teinte va avec l'encre qui se lit dessus : choisir une **paire**, jamais deux couleurs sans lien.

### Base

| Jeton | Valeur | Usage |
|---|---|---|
| `background` | `#EEF1F7` | Fond de tous les écrans et des feuilles |
| `surface` | `#FFFFFF` | Cartes, champs, touches, barre du bas |
| `ink` | `#0E1320` | Texte principal, bouton sombre, choix retenu |
| `inkSecondary` | `#525D73` | Aides, titres de section, dates, valeurs grises |
| `inkMuted` | `#8A93A6` | Indications, valeurs vides, flèches discrètes |
| `line` | `#C9CFDB` | Bords au repos, poignée des feuilles |
| `lineStrong` | `#B6BDCB` | Contours des boutons blancs, flèche › des lignes |
| `track` | `#DDE2EC` | Séparateurs, barres vides |
| `fill` | `#E4E8F0` | Pastilles, bouton désactivé |
| `fillSoft` | `#F4F6FA` | Sous les sous-catégories ouvertes, cases du plan |

### Marque

| Jeton | Valeur | Usage |
|---|---|---|
| `mint` | `#5EEAB5` | Bouton principal, bouton +, carte « Disponible », coche des confirmations ; texte `ink` dessus |
| `coin` | `#FFC247` | La pièce du logo, et elle seule |

### Sens

| Sens | Encre | Teintes et traits | Usage |
|---|---|---|---|
| Bon, argent qui entre | `accent` `#0A7355` | `accentTint` `#E9F8F1`, `accentTintStrong` `#D5F2E4`, `accentTintOpen` `#CDEFE0`, `accentSoft` `#F2FBF7`, `accentDone` `#D6F5E8`, `accentDash` `#7FCBA8`, `accentDeep` `#1F3A30`, `accentStripInk` `#0A5A43` | Revenus, créances, actions texte, bord actif, curseur, interrupteurs, « Dans les temps » |
| Ce que je dois, argent qui sort | `debtInk` `#8A4B12` | `debtTint` `#FFE6D3`, `debtLine` `#E8A878`, `debtEdge` `#F2CFB3`, `debtDraft` `#FFF4EC`, `debtDash` `#E3A97A` | Dépenses, dettes, part remplacée d'une restauration |
| Projets, argent mis de côté | `projectInk` `#33528A` | `projectTint` `#E1E8F6`, `projectLine` `#8FA8D6`, `projectTrack` `#E8EDF6`, `projectDeep` `#24406E` | Projets, réservé dans Comptes, notes d'information bleues |
| Transfert | `ink` | `transferTint` `#EEF2FA`, `transferEdge` `#C6D3EC`, `transferDash` `#9DB2DD` | Montant d'un transfert |
| Alerte | `warningInk` `#8A5A00` | `warning` `#D99A1C`, `warningTint` `#FCEFD2`, `warningSoft` `#FFF8E8` (encre `warningSoftInk` `#6B4A00`), `warningTrack` `#F6E2B4` | Budget à 80 %, sauvegarde ancienne, notes ambre |
| Retard, danger | `danger` `#B3321A` | `dangerTint` `#FBE3DE`, `dangerSoft` `#FFF1ED`, `dangerDeep` `#7C1F0C`, `dangerTrack` `#FFD3C8`, `dangerOnInk` `#FFB4A2` | Retard, dépassement, supprimer, refus |
| Graphique de l'Aperçu | — | `chartIn` `#7CCFAA` (barres des entrées ; les sorties sont en `debtLine`), `chartOutAhead` `#F2E3D6` et `chartInAhead` `#DDF1E7` (ce qui n'a pas encore commencé), `chartCompared` `#7C8599` (courbe de la période comparée ; ses bâtonnets sont en `track`) | Onglet Évolution de l'Aperçu |

### Couleurs des catégories

Le nom gardé dans la base, puis la teinte de la tuile et de la barre (27 novembre 2026, [ADR 0014](../adr/0014-couleur-des-categories.md)) ; l'icône reste à l'encre.

| Nom | Teinte | Nom | Teinte |
|---|---|---|---|
| `peach` Pêche | `#E8A878` | `lavender` Lavande | `#B9A8E2` |
| `apricot` Abricot | `#F2C48D` | `blue` Bleu | `#9DB4E0` |
| `sand` Sable | `#DCC79A` | `sky` Ciel | `#8ED0E6` |
| `coral` Corail | `#EE9F92` | `mint` Menthe | `#5EEAB5` |
| `rose` Rose | `#D9A0C4` | `green` Vert | `#7FCBA8` |
| `grey` « Autres » | `#C9CFDB` | | |

### Voiles et ombres

| Jeton | Valeur | Usage |
|---|---|---|
| `scrim` | encre à 42 % | Derrière une feuille, une ligne ouverte, une astuce, un guide : la page reste lisible (27 novembre 2026) |
| `veil` | encre à 12 % | Derrière un menu, le choix du mois |
| `blurVeil` | encre à 32 %, sur un flou de 8 | Le fond flouté, derrière une tuile agrandie seulement (27 novembre 2026) |
| `barShadow` | encre à 18 % | Barre flottante (clavier, sélection) |
| `fanShadow` | noir à 25 % | Choix de l'éventail du + |

## Typographie

`lib/ui/theme/kibuo_theme.dart`, classe `KibuoType` (« un style par rôle, et aucun autre »).

- **Plus Jakarta Sans** (`KibuoTheme.displayFont`) : titres, montants, touches du clavier.
- **Inter** (`textFont`) : tout le reste, avec son axe de taille optique réglé comme dans un navigateur.
- **Space Grotesk** (`brandFont`) : seulement le nom à côté du logo. Le nom seul se dessine avec `KibuoWordmark` (la pièce en point du i).
- Les deux polices sont variables : changer de graisse avec l'extension `.weight(600)`, jamais `fontWeight` seul.

| Style | Police, taille, graisse | Rôle |
|---|---|---|
| `tabTitle` | Jakarta 24, 700 | Titre d'onglet (Accueil, Opérations, Plus) |
| `screenTitle` | Jakarta 22, 700 | Titre d'écran avec ‹ |
| `sheetTitle` | Jakarta 20, 700 | Titre de feuille avec ✕ |
| `bigAmount` | Jakarta 34, 700 | Grand montant (saisie, fiche) |
| `highlight` | Jakarta 28, 700 | Montant ou code mis en avant |
| `enteredValue` | Jakarta 26, 700 | Valeur tapée (taux, solde) |
| `cardTitle` | Jakarta 17, 700 | Titre de carte, montant d'une ligne |
| `key` | Jakarta 22, 500 | Touche du clavier |
| `itemName` | Inter 16, 600 | Nom d'un élément (une carte par élément) |
| `rowLabel` | Inter 15, 500 | Libellé d'une ligne |
| `body` | Inter 14, 400 | Texte, valeurs |
| `sectionTitle` | Inter 13, 600, gris | Titre de section, titre de groupe |
| `help` | Inter 13, 400, gris, interligne 18 | Aide sous une carte |
| `caption` | Inter 12, 400, gris | Légende, deuxième ligne |
| `button` | Inter 16, 600 | Bouton |
| `buttonSmall` | Inter 15, 600 | Bouton secondaire, action texte |

Chiffres : les montants s'écrivent avec `context.money(m)` (`lib/ui/money/money_format.dart`), qui suit la devise (pas de décimales pour le franc congolais) et la langue (« 30,00 $ », « 2 800 FC » ; en anglais « $30.00 », « FC 2,800 »). Les montants longs se raccourcissent selon le réglage « Montants longs » (`FitAmount`, voir PRODUCT). Le signe moins est `−` (U+2212), les espaces de milliers sont insécables.

## Espaces, rayons, hauteurs

`KibuoSpace`, `KibuoTheme` dans `lib/ui/theme/kibuo_theme.dart`. La règle d'usage (l'échelle entre les blocs, les mesures de la planche à l'intérieur d'un composant) est dans DIRECTION, « Espaces, coins et hauteurs ».

| Espaces (`KibuoSpace`) | Valeur | Usage |
|---|---|---|
| `xs` | 4 | Dans un groupe : libellé et valeur |
| `s` | 8 | Icône et texte, titre de groupe et éléments |
| `m` | 12 | Entre deux cartes ou deux champs |
| `l` | 16 | Marges d'écran (`screenMargin`), intérieur des cartes |
| `xl` | 24 | Avant le bouton principal, sous le contenu d'une feuille |
| `xxl` | 32 | Entre deux grandes parties d'un écran |

Entre deux groupes d'une liste : 20 (`GroupTitle.gap`).

| Rayons | Valeur | Usage |
|---|---|---|
| `radiusPill` | 12 | Pastille, tuile d'icône de 36 |
| `radiusTile` | 14 | Champ texte, note, tuile |
| `radiusField` | 16 | Champ de montant, touche |
| `radiusCard` | 18 | Carte, bouton principal |
| `radiusFeatured` | 22 | Carte mise en avant (Disponible, haut d'une fiche) |
| `radiusSheet` | 26 | Haut des feuilles |

| Hauteurs | Valeur | Usage |
|---|---|---|
| `heightTouch` | 44 | Zone tactile minimale |
| `heightSecondary` | 48 | Bouton secondaire (Plus tard, Annuler) |
| `heightKey` | 50 | Touche du clavier |
| `heightField` | 52 | Champ texte, ligne de réglage |
| `heightPrimary` | 54 | Bouton principal |

- **Sous la barre d'onglets** : `KibuoTheme.belowTabBar` = 160 sous le contenu d'une page qui a le menu du bas (le menu, son + et son fondu font 132, plus 28 pour lire les dernières lignes).
- **Bas d'écran** : `BottomAction` (8 au-dessus, 24 au-dessus de la barre du téléphone) ; **bas de feuille** : `sheetPadding` (16 sur les côtés, 24 au-dessus de la barre du téléphone).
- **Ombres** : seulement la barre du bas, les barres flottantes et l'éventail du + (`barShadow`, `fanShadow`). Les cartes n'ont pas d'ombre.

## Icônes

- **Phosphor** (licence MIT), embarquée depuis ses fichiers de police (`assets/icons/`, `lib/ui/theme/kibuo_icons.dart`, classe `KibuoIcons`). Graisse régulière par défaut ; grasse pour le + et la croix de l'éventail ; pleine pour l'onglet actif.
- Pour ajouter une icône : chercher son point de code dans le `style.css` de `@phosphor-icons/web` 2.1.2, ajouter une constante.
- Tailles courantes : 18 dans une tuile de 36, 20 dans une tuile de 40, 22 dans la barre du bas, 16 à 18 pour la flèche ›.
- La **barre du bas** a ses icônes dessinées pour kibuo (`lib/ui/shell/tab_icons.dart`, planche `BarreIconesPh`, validée) : trait au repos, pleine et menthe à l'onglet actif.
- Les icônes de catégories et de projets sont des noms stockés (`categoryIcons`, `projectIcon()`).

## Le kit (`lib/ui/kit/`)

Un composant naît à la deuxième apparition d'un élément. Les marges restent à l'appel, jamais dans le composant. Chaque composant cite sa planche dans son commentaire.

### Pages et feuilles

| Composant | Fichier | Quand |
|---|---|---|
| `TabHeader` | `sheet.dart` | Haut d'un onglet : titre de 44, actions à droite, pas de flèche retour |
| `FormTopBar` | `form_top_bar.dart` | Haut d'un écran de création : « Annuler », titre au centre |
| `StepTitle` | `sheet.dart` | « Étape 2 sur 4 » et le grand titre du premier lancement |
| `showKibuoSheet` | `sheet.dart` | Toute feuille : poignée, titre avec ✕, contenu, marges |
| `SheetHandle`, `SheetHeader`, `withSheetHandle`, `sheetPadding` | `sheet.dart` | Pièces d'une feuille faite à la main |
| `BottomAction` | `sheet.dart` | Le bouton principal en bas d'un écran, au-dessus du clavier ouvert |
| `showChoiceSheet` | `choice_sheet.dart` | Feuille de choix cochés (Délai, Rappel, Diviser le plan par) |
| `confirmRemoval`, `RemovalSummary` | `sheet.dart` | Confirmer une suppression : ce qui est concerné, la conséquence, le bouton rouge |
| `showConfirmSheet`, `ConfirmAction`, `SavedLine` | `confirm_sheet.dart` | Confirmation qui se ferme seule (« Remboursement enregistré », « Mis de côté »), avec « Annuler » |
| `GuideSpotlight`, `GuideCard`, `guideGap` | `guide.dart` | Guide de première visite : la page voilée sauf une fenêtre autour de l'élément montré, 8 de marge de chaque côté ; la carte blanche « 1 sur 2 », titre, mots, « Passer » et l'action menthe |
| `PageVeil` | `page_veil.dart` | Ce qui reste derrière ce qui passe devant, bord à bord : le voile de la feuille du + (encre à 42 %) derrière une ligne ouverte, une astuce, un guide (avec sa fenêtre) ; flouté (flou de 8, encre à 32 %) derrière une tuile agrandie. Seul le voile apparaît en fondu (27 novembre 2026) |
| `AutoClose` | `auto_close.dart` | La barre menthe qui se vide sous une confirmation |
| `showKibuoToast` | `toast.dart` | Message court au-dessus de la barre d'onglets (« Reporté à demain », avec « Annuler ») ; jamais sur une fiche qui a un bouton en bas |

### Cartes et lignes

| Composant | Fichier | Quand |
|---|---|---|
| `KibuoCard` | `cards.dart` | Carte blanche ordinaire (avec `onTap`) |
| `FeaturedCard` | `cards.dart` | Carte menthe qui met une valeur en avant |
| `ItemCard` | `cards.dart` | Une carte par élément géré (devise, compte) |
| `SettingsCard` | `cards.dart` | Carte de lignes séparées par un trait |
| `SettingsRow` | `cards.dart` | Ligne de réglage : libellé, valeur grise contre ›, 52 de haut |
| `SwitchRow`, `SettingsSwitch` | `cards.dart` | Ligne avec interrupteur |
| `IconRow` | `cards.dart` | Ligne avec tuile teintée (page Plus) |
| `ValueRow` | `value_row.dart` | Ligne d'une feuille : libellé gris, « valeur › » en gras |
| `CheckChoice`, `DisplayChoice` | `cards.dart` | Choix d'une feuille, choix d'affichage |
| `ChoiceTile` | `choice_tile.dart` | Grand choix du premier lancement |
| `SectionTitle`, `HelpText` | `cards.dart` | Petit titre au-dessus, aide sous une carte |
| `GroupTitle`, `GroupNote` | `group_title.dart` | Titre d'un groupe de liste, repliable |
| `DayHeader`, `dayLabel` | `day_header.dart` | Un jour d'opérations, son total, replier |
| `EmptyCard` | `empty_card.dart` | Liste vide : pointillés, icône, aide, action |
| `NoticeCard` | `operation_card.dart` | Une phrase encadrée avec son icône (notes bleue, ambre, rouge) |
| `OperationHero` | `operation_card.dart` | Haut d'une opération pas encore faite (brouillon, prévue) |
| `MonthSummaryCard` | `month_summary_card.dart` | Bilan du mois (accueil, Budgets) |
| `CardArrow` | `card_arrow.dart` | La › d'une carte qui ouvre une page (à 12 du bord) |
| `CardLink` | `card_link.dart` | Lien vert en fin de dernière ligne (« Mettre de côté › ») |
| `IconTile` | `icon_tile.dart` | Icône sur un carré teinté (36 par défaut) |
| `StatusPill` | `status_pill.dart` | Étiquette « En retard », « En avance », « Terminé » |
| `DashedBorder` | `dashed_border.dart` | Contour pointillé (création, brouillon, codes facultatifs) |
| `ScrollingLine` | `scrolling_line.dart` | Une ligne trop longue qui défile lentement |
| `FadingRow` | `fading_row.dart` | Rangée qui défile de côté, bords en fondu |

### Barres et montants

| Composant | Fichier | Quand |
|---|---|---|
| `SpentBar`, `SpentShare` | `spent_bar.dart` | Barre « % dépensés » de l'accueil et de la liste |
| `HatchedBar` | `hatched_bar.dart` | Barre avec la part ajoutée ou retirée hachurée |
| `QuickAmounts` | `quick_amounts.dart` | Montants prêts côte à côte (ce qui manque, la moitié) |
| `typeAmount` | `amount_sheet.dart` | Taper un montant au clavier dans une feuille, plafond compris |

### Champs et clavier

| Composant | Fichier | Quand |
|---|---|---|
| `KibuoTextField` | `fields.dart` | Champ texte (option `secret` avec l'œil) |
| `ValueField`, `OperationAmountField`, `CurrencyPill`, `BlinkingCaret` | `fields.dart` | Valeur tapée au clavier kibuo, grand montant d'une saisie |
| `DateField` | `fields.dart` | Une date à toucher |
| `RefusalLine` | `fields.dart` | Ligne rouge de refus sous un montant (avec vibration) |
| `KibuoKeypad`, `KeypadPanel`, `typeKey`, `revealAboveKeypad` | `keypad.dart` | Le clavier kibuo, le même partout |
| `MonthPicker` | `month_picker.dart` | Année et 12 mois |
| `IconGrid` | `icon_grid.dart` | Grille d'icônes à choisir |

### Choix et boutons

| Composant | Fichier | Quand |
|---|---|---|
| `KibuoButton` + `ButtonKind` | `buttons.dart` | `primary` (menthe, un seul par écran), `secondary` (blanc), `outline`, `dark` (Terminé), `danger` (contour rouge), `create` (pointillés), `mint` (48, dans une feuille) |
| `TextAction` | `buttons.dart` | Action texte verte |
| `ActionUnderCard` | `buttons.dart` | Bouton texte centré sous une carte |
| `HoldToConfirm` | `hold_button.dart` | Appui maintenu pour un geste lourd ; `dark: true` pour la restauration |
| `ChoiceStrip`, `CountStepper` | `choice_strip.dart` | Choix côte à côte sur une bande grise, « − 2 + » |
| `SegmentedTabs` | `segmented_tabs.dart` | Onglets sur une bande blanche |
| `TabStrip` | `tab_strip.dart` | Choix sur une bande grise, le choisi en blanc ; un choix impossible grisé (onglets de l'Aperçu, choix de la feuille « Période ») |
| `FilterChipButton`, `ChoiceMenu`, `ChoiceRow`… | `choice_menu.dart` | Filtres de liste et leur menu |
| `Haptics`, `RefuseOnAppear` | `haptics.dart` | Vibrations : `tap`, `confirm`, `refuse` |

Hors du kit mais partagés : `OperationRow` (`lib/ui/transactions/operation_row.dart`), `ProjectTile` et `ProjectBar` (`lib/ui/projects/project_parts.dart`), `BackupLink` (`lib/ui/backup/start_restore_sheet.dart`).

L'écran « Système de design » de l'app (Plus, version d'essai seulement : `lib/ui/kit/design_system_screen.dart`) montre les pièces de base.

## Motifs récurrents

Chaque motif a sa règle détaillée dans DIRECTION ; ici, quoi utiliser.

- **Feuille** : `showKibuoSheet` ; titre en `sheetTitle` avec ✕ ; pas de bouton « Annuler » (on ferme par ✕, toucher à côté, glisser, retour) ; un second bouton seulement s'il dit autre chose (« Plus tard »).
- **Confirmation « … faite »** : `showConfirmSheet` (titre « Mis de côté », « Remboursement enregistré »), une `SavedLine` (coche menthe, ce qui a été fait, montant), éventuellement une barre, « Annuler » ; elle se ferme seule (`AutoClose`).
- **Appui long pour confirmer** : `HoldToConfirm`, pour un geste lourd sans autre feuille de confirmation (tout effacer, remplacer par une sauvegarde). Libellé « Maintenir pour … », puis « Continuez d'appuyer… ».
- **Supprimer** : `confirmRemoval` (bouton rouge) ; « Supprimer … » est un `ActionUnderCard` rouge sous la dernière carte ; avec le code des actions importantes, `confirmWithCode` ensuite.
- **Toast** : `showKibuoToast` pour un message court sur un onglet ; sur une fiche, préférer la feuille de confirmation.
- **Lignes « À traiter »** : `lib/ui/home/todo.dart` (`TodoLook`) : tuile teintée de 36, titre « Nom · montant », deuxième ligne colorée selon l'urgence, action verte « … › » à droite ; glisser à gauche pour « Plus tard ». Groupes Urgent (point rouge), Cette semaine (ambre), Rappels (sans point).
- **Notes** : `NoticeCard`. Bleue (`projectTint` / `projectInk`) pour une information (un transfert sera enregistré) ; ambre (`warningSoft` / `warningSoftInk`) pour attirer l'attention ; rouge (`dangerTint` / `danger`) pour un refus.
- **États vides** : `EmptyCard` dans une liste ; sur l'accueil, une section sans contenu disparaît.
- **Montants** : `context.money()` ; couleur selon le sens (revenu `accent`, dépense `debtInk`, projet `projectInk`) ; une ligne d'opération montre le signe.
- **Dates relatives** : `dayLabel` (« Aujourd'hui », « Hier », « Mardi 10 novembre ») ; durées restantes « 9 jours », « 7 semaines », « 4 mois » (`projectTimeLeft`) ; jours de calendrier avec `calendarDays` (`lib/domain/calendar.dart`).

## Le ton des textes

Observé dans les textes validés ; le vocabulaire officiel est dans [GLOSSARY.md](../../GLOSSARY.md), à suivre pour tout nom de concept.

- **Vouvoiement** : « Vous retrouvez vos données », « Votre dernière sauvegarde ».
- **Phrases courtes et concrètes**, qui disent la conséquence : « Aucune opération : les 50,00 $ redeviennent libres sur Rawbank épargne. »
- **Majuscule seulement en début de libellé** ; le nom de l'app toujours en minuscules : **kibuo**.
- **Guillemets français** « … » avec espaces insécables ; « … » en points de suspension typographiques ; apostrophe typographique ’.
- **Boutons à l'infinitif ou au nom de l'action** : « Enregistrer », « Mettre de côté », « Reprendre », « Voir mes données ». Pas de « OK ».
- **Une feuille demande par une question qui nomme l'objet** : « Revenir au 3 novembre ? », « Supprimer Voyage ? ».
- **Le séparateur** des informations d'une ligne est « · » (« Dette · demain », « CDF · 20,00 $ libres »).
- Mots à éviter : à vérifier dans GLOSSARY (par exemple « transaction » pour une opération, « solde » au lieu de « disponible » quand on parle de ce qui est libre).
- Tous les textes passent par `lib/l10n/app_fr.arb` et `app_en.arb`, puis `flutter gen-l10n`.
