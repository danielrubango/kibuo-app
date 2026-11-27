# Planches du canvas « Kibuo - Identité et directions »

Export du 24 novembre 2026 : les **258 planches** `.dc.html` du canvas de design, son plan (`canvas.json` : pages, titres, positions, tailles) et des captures PNG des planches principales (`captures/`). Le canvas lui-même est un artifact privé de claude.ai : https://claude.ai/code/artifact/5ee02d0b-b510-42a6-8ec9-dca67745523c. La méthode de travail sur un canvas (variantes, page « En cours », nettoyage) est dans [WORKING.md](../../WORKING.md#le-canvas-de-design) ; les règles tirées des planches sont dans [DIRECTION.md](../DIRECTION.md) et les valeurs dans [SYSTEM.md](../SYSTEM.md).

## Ouvrir et mesurer une planche

- Ouvrir le fichier `.dc.html` dans Chrome ou Firefox depuis ce dossier. `support.js` est le moteur d'affichage du type « Design » du canvas (basé sur React, licence MIT) : il fait tourner les listes et valeurs calculées des planches. Sans lui, la planche est vide.
- Pour mesurer, lire le HTML : les tailles, marges et couleurs sont écrites dans les styles. La largeur et la hauteur du cadre (390 × 844 pour un écran de téléphone, 340 pour un petit écran) sont dans `canvas.json`.
- Capturer une planche (Chrome en ligne de commande ; les fichiers locaux demandent l'autorisation, le moteur a besoin de temps) :

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars --allow-file-access-from-files --virtual-time-budget=5000 --window-size=390,844 --screenshot=captures/Aujourdhui.png "file://$PWD/Aujourdhui.dc.html"
```

## Créer ou modifier une planche

Une planche nouvelle se fait dans le canvas (artifact « Design » de claude.ai), pas dans ce dossier : ce dossier est une copie de lecture. Après une séance de design validée, réexporter les planches touchées ici (le fichier `.dc.html` et `canvas.json`), et refaire leur capture si elle existe. Un agent sans accès au canvas peut dessiner ses variantes dans un nouvel artifact, ou en HTML simple dans ce dossier avec un nom qui dit la variante (`EcranA.html`, `EcranB.html`), en reprenant les valeurs de SYSTEM.md.

## Ce que veut dire l'état

- **validée le …** : la date est écrite dans le titre de la planche ou dans DIRECTION.
- **retenue** : la planche est rangée sur la page de son domaine, ce qui veut dire, dans la méthode du canvas, qu'elle a été choisie ; sa date de validation n'est pas écrite (chercher la règle correspondante dans DIRECTION ou PRODUCT, qui portent souvent la date).
- **écartée** : variante non retenue (page « En cours » marquée non retenue, ou planche sans page). Les raisons connues sont dans DIRECTION, « Variantes écartées et pourquoi ».
- **revue : Proche, À revoir, Écart voulu** : la page « Revue de fidélité » compare les écrans construits aux maquettes (15 novembre).
- **pas encore construit** dans la colonne Code : la planche est validée mais l'écran n'existe pas encore dans l'app (voir [STATE.md](../../STATE.md)).

La colonne Code donne le fichier principal sous `lib/ui/` ; un composant du kit qui cite la planche dans son commentaire n'est pas toujours listé. « à vérifier » : pas trouvé avec certitude.

## Captures

`captures/` contient 39 planches rendues à leur taille : l'accueil, la liste des opérations et la recherche, le +, À traiter, Budgets, Projets, Dettes, la confirmation (ConfirmA) et la ligne d'opération d'une dette (OpDetteA4), Comptes, Sauvegarde et restauration, le premier lancement, la sécurité, l'Aperçu, Plus et Réglages (pas encore construits), l'export CSV, le système de design (couleurs, textes, espaces, boutons), la barre du bas, le logo et la récurrence. Les autres planches se rendent avec la commande ci-dessus.

Les captures PNG de la page « Revue de fidélité » (écran construit à côté de la maquette) n'ont pas été exportées : elles vivent seulement dans le canvas.

## Les planches, page par page

### Identité (6)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [Demarrage](Demarrage.dc.html) | Démarrage : écran d’Android puis écran Kibuo (validé) | validée (date à vérifier) | start/start_screen.dart, android/app/src/main/res (à vérifier) |
| [DemarrageEC](DemarrageEC.dc.html) | Démarrage : rebond de la pièce, tirelire qui s’aplatit, nom en ressort (validé le 17 novembre) | validée le 17 novembre | start/start_screen.dart |
| [LogoA1](LogoA1.dc.html) | Logo retenu et icône Android : formes, petites tailles, icône à thème | retenue | brand/kibuo_mark.dart, android/app/src/main/res |
| [Main](Main.dc.html) | Logo retenu | retenue | brand/kibuo_mark.dart |
| [NomChoix](NomChoix.dc.html) | Le nom : kibuo gardé face à bombika, akibao, tirelia (17 novembre) | retenue | — |
| [NomMinusculeB](NomMinusculeB.dc.html) | kibuo en minuscules, la pièce en point du i (validé le 17 novembre) | validée le 17 novembre | brand/kibuo_wordmark.dart |

### Système de design (8)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [DSBoutons](DSBoutons.dc.html) | Boutons | retenue | theme/, kit/ (voir SYSTEM.md) |
| [DSChamps](DSChamps.dc.html) | Champs de saisie | retenue | theme/, kit/ (voir SYSTEM.md) |
| [DSCouleurs](DSCouleurs.dc.html) | Couleurs | retenue | theme/, kit/ (voir SYSTEM.md) |
| [DSEspaces](DSEspaces.dc.html) | Espaces, coins et hauteurs | retenue | theme/, kit/ (voir SYSTEM.md) |
| [DSFeuilles](DSFeuilles.dc.html) | Feuilles, clavier et en-têtes | retenue | theme/, kit/ (voir SYSTEM.md) |
| [DSListes](DSListes.dc.html) | Listes et cartes | retenue | theme/, kit/ (voir SYSTEM.md) |
| [DSPolices](DSPolices.dc.html) | Polices : C retenue | retenue | theme/, kit/ (voir SYSTEM.md) |
| [DSTextes](DSTextes.dc.html) | Textes | retenue | theme/, kit/ (voir SYSTEM.md) |

### Revue de fidélité (15)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [RevueCodeOublie](RevueCodeOublie.dc.html) | Code oublié · Proche | revue : Proche | — |
| [RevueCodeRecup](RevueCodeRecup.dc.html) | Noter le code de récupération · Écart voulu | revue : Écart voulu | — |
| [RevueDelaiB](RevueDelaiB.dc.html) | Verrouillage · Proche | revue : Proche | — |
| [RevueDevises](RevueDevises.dc.html) | Devises · À revoir | revue : À revoir | — |
| [RevueLancement2](RevueLancement2.dc.html) | Choix d’une devise · Écart voulu | revue : Écart voulu | — |
| [RevuePinCreaC2](RevuePinCreaC2.dc.html) | Créer le code · Proche | revue : Proche | — |
| [RevuePinEmpreinte](RevuePinEmpreinte.dc.html) | Proposer l’empreinte · Proche | revue : Proche | — |
| [RevueRecupIllisible](RevueRecupIllisible.dc.html) | Données illisibles · Proche | revue : Proche | — |
| [RevueRecupPreuve](RevueRecupPreuve.dc.html) | Prouver qu’on a noté le code · Proche | revue : Proche | — |
| [RevueRecupReglage](RevueRecupReglage.dc.html) | Code de récupération (réglage) · Proche | revue : Proche | — |
| [RevueRecupSaisie](RevueRecupSaisie.dc.html) | Saisir le code de récupération · Proche | revue : Proche | — |
| [RevueSecuConfid](RevueSecuConfid.dc.html) | Confidentialité · Proche | revue : Proche | — |
| [RevueSecurite](RevueSecurite.dc.html) | Sécurité · À revoir | revue : À revoir | — |
| [RevueTauxReglages](RevueTauxReglages.dc.html) | Feuille du taux · À revoir | revue : À revoir | — |
| [RevueVerrouC2](RevueVerrouC2.dc.html) | Déverrouiller · Proche | revue : Proche | — |

### Accueil et navigation (32)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [Aujourdhui](Aujourdhui.dc.html) | Accueil « Aujourd’hui » : disponible, bilan du mois, dettes et créances, à traiter, à venir | retenue | home/home_screen.dart, home/todo.dart, kit/month_summary_card.dart |
| [BarreIconesPh](BarreIconesPh.dc.html) | Barre du bas · Phosphor et pastille (validée) | validée (date à vérifier) | shell/tab_icons.dart |
| [BrouS1](BrouS1.dc.html) | plusieurs brouillons : cocher, toucher pour ouvrir la fiche | retenue | home/drafts_sheet.dart |
| [BrouS1Un](BrouS1Un.dc.html) | un seul brouillon : la ligne ouvre la fiche, « Valider » | retenue | home/drafts_sheet.dart |
| [DettesCartes](DettesCartes.dc.html) | Dettes et créances (première visite guidée) | retenue | obligations/debt_home_cards.dart |
| [DettesListeCreances](DettesListeCreances.dc.html) | « On me doit › » : la liste ouverte sur On me doit | retenue | obligations/debts_screen.dart |
| [DettesListeDois](DettesListeDois.dc.html) | « Je dois › » : la liste ouverte sur Je dois | retenue | obligations/debts_screen.dart, theme/kibuo_colors.dart |
| [FicheDette](FicheDette.dc.html) | Fiche d'une dette | retenue | obligations/debt_screen.dart |
| [FicheDettePetit](FicheDettePetit.dc.html) | Fiche d'une dette, petit écran (340 px) | retenue | obligations/debt_screen.dart |
| [Operations](Operations.dc.html) | Opérations | retenue | transactions/operations_list.dart |
| [Plus](Plus.dc.html) | Plus : mes espaces, Réglages et Sauvegarde sur une ligne chacun, aide | retenue | more/plus_page.dart |
| [PlusAncienne](PlusAncienne.dc.html) | Sauvegarde ancienne : point ambre sur l’icône, texte en ambre | retenue | more/plus_page.dart |
| [PlusBtnB1](PlusBtnB1.dc.html) | Toucher + : la feuille « Ajouter », Dépense en grand, « Refaire » | retenue | kit/sheet.dart, shell/add_sheet.dart, theme/kibuo_theme.dart |
| [PlusBtnC1](PlusBtnC1.dc.html) | Maintenir + : l’éventail, glisser vers un choix | retenue | shell/plus_fan.dart |
| [PlusBtnC2](PlusBtnC2.dc.html) | Astuce de l’appui long, après quelques ouvertures du menu | retenue | shell/app_shell.dart |
| [ProjetP1](ProjetP1.dc.html) | progression, montant et compte à toucher, « Mettre de côté » | retenue | kit/hatched_bar.dart, kit/quick_amounts.dart, kit/value_row.dart |
| [ReclamerR1](ReclamerR1.dc.html) | la personne et le retard, le message, « Envoyer » | retenue | obligations/claim_sheet.dart |
| [RembourserV3](RembourserV3.dc.html) | progression de la dette, montant, compte, date, « Rembourser » | retenue | kit/hatched_bar.dart, kit/value_row.dart, obligations/debt_screen.dart |
| [SauvW2](SauvW2.dc.html) | déjà une sauvegarde : rappel, dossier « Changer », chiffrement | retenue | backup/backup_sheet.dart, kit/operation_card.dart |
| [SauvW2Premiere](SauvW2Premiere.dc.html) | première sauvegarde : « Sélectionner » un dossier | retenue | theme/kibuo_colors.dart |
| [TauxReglages](TauxReglages.dc.html) | Réglages › Devises › Modifier | retenue | settings/currency_screens.dart |
| [TauxTraiter](TauxTraiter.dc.html) | « À traiter » › Modifier | retenue | settings/currency_screens.dart |
| [Total_negatif](Total_negatif.dc.html) | Disponible négatif | retenue | home/home_screen.dart |
| [Total_positif](Total_positif.dc.html) | Situation normale | retenue | home/home_screen.dart |
| [Total_projetzero](Total_projetzero.dc.html) | Projets à 0 | retenue | home/home_screen.dart |
| [Total_sansprojet](Total_sansprojet.dc.html) | Aucun projet | retenue | home/home_screen.dart |
| [Total_zero](Total_zero.dc.html) | Tout à zéro | retenue | home/home_screen.dart |
| [TraiterEtatMixte](TraiterEtatMixte.dc.html) | 1 urgence : elle passe en tête, puis la semaine | retenue | home/todo.dart |
| [TraiterEtatRappels](TraiterEtatRappels.dc.html) | Seulement des rappels : pas de point | retenue | home/todo.dart |
| [TraiterEtatSemaine](TraiterEtatSemaine.dc.html) | Rien d’urgent : point ambre, cette semaine | retenue | home/todo.dart |
| [TraiterEtatUrgent](TraiterEtatUrgent.dc.html) | Avec des urgences : point rouge, les 3 urgences | retenue | home/todo.dart |
| [TraiterListe](TraiterListe.dc.html) | La liste complète : lignes blanches, couleur dans l’icône, actions en lien | retenue | home/todo.dart |

### Premier lancement (6)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [Lancement1](Lancement1.dc.html) | 1. Langue | retenue | start/first_launch.dart |
| [Lancement2](Lancement2.dc.html) | 2. Devise principale | retenue | start/first_launch.dart |
| [Lancement3](Lancement3.dc.html) | 3. Premier compte | retenue | start/first_launch.dart, accounts/account_form_screen.dart |
| [Lancement3Decouvert](Lancement3Decouvert.dc.html) | 3. Premier compte : le découvert (fermé, ouvert) | retenue | accounts/account_form_screen.dart |
| [Lancement4](Lancement4.dc.html) | 4. Protection | retenue | start/first_launch.dart |
| [RestauNeuf](RestauNeuf.dc.html) | « J’ai une sauvegarde » : contenu flouté et « Restaurer » grisé tant que le mot de passe n’est pas bon | retenue | backup/start_restore_sheet.dart |

### Réglages (55)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [APropos](APropos.dc.html) | À propos : logo, version, confidentialité, licences | retenue | more/about_screen.dart |
| [AideSupport](AideSupport.dc.html) | Aide et support : questions fréquentes, WhatsApp et e-mail | retenue | pas encore construit |
| [CacheRecentes](CacheRecentes.dc.html) | Kibuo masqué dans les applications récentes | retenue | settings/security_screens.dart |
| [CatModif](CatModif.dc.html) | Modifier la catégorie (validé) | validée (date à vérifier) | categories/category_form_screen.dart |
| [CatNouvelle](CatNouvelle.dc.html) | Nouvelle sous-catégorie (validé) | validée (date à vérifier) | categories/category_form_screen.dart |
| [Categories](Categories.dc.html) | Catégories | retenue | categories/categories_screen.dart |
| [CodeOublie](CodeOublie.dc.html) | « Code oublié ? » | retenue | lock/forgot_sheet.dart |
| [CodeRecup](CodeRecup.dc.html) | Code de récupération | retenue | lock/recovery_screens.dart |
| [CompteModifA](CompteModifA.dc.html) | Modifier le compte : type et nom, puis « Archiver » en ligne rouge (le solde de départ ne se modifie plus) | retenue | accounts/account_form_screen.dart |
| [CompteNouveau](CompteNouveau.dc.html) | Nouveau compte (validé le 15 novembre) | validée le 15 novembre | accounts/account_form_screen.dart |
| [Comptes](Comptes.dc.html) | Comptes : un compte par carte, projets dessous, puces qui changent le total | retenue | accounts/accounts_screen.dart |
| [ComptesAffichage](ComptesAffichage.dc.html) | Comptes : « Affichage des comptes », seulement avec plusieurs devises | retenue | accounts/accounts_screen.dart |
| [ComptesRepli](ComptesRepli.dc.html) | Comptes : types repliés (nom, nombre de comptes, total) | retenue | accounts/accounts_screen.dart |
| [ConfirmArchive](ConfirmArchive.dc.html) | Archiver un compte | retenue | accounts/account_form_screen.dart |
| [ConfirmCategorie](ConfirmCategorie.dc.html) | Supprimer une catégorie | retenue | categories/category_form_screen.dart |
| [ConfirmDevises](ConfirmDevises.dc.html) | Retirer des devises | retenue | settings/currency_screens.dart |
| [DecouvertA](DecouvertA.dc.html) | Découvert : la limite dans la carte | retenue | accounts/account_form_screen.dart |
| [DecouvertComptes](DecouvertComptes.dc.html) | Comptes : le découvert de chaque compte | retenue | accounts/accounts_screen.dart |
| [DecouvertSousZero](DecouvertSousZero.dc.html) | Retirer le découvert d’un compte sous zéro | retenue | accounts/account_form_screen.dart |
| [DelaiB](DelaiB.dc.html) | Sécurité › Verrouillage (délai dans une feuille) | retenue | settings/security_screens.dart |
| [Devises](Devises.dc.html) | Devises | retenue | settings/currency_screens.dart |
| [EditDevC](EditDevC.dc.html) | Devises › Modifier : « Retirer » à droite (validé) | validée (date à vérifier) | settings/currency_screens.dart |
| [EditDevN](EditDevN.dc.html) | Devises : « Modifier » en haut à droite (validé) | validée (date à vérifier) | settings/currency_screens.dart |
| [ExportCSV](ExportCSV.dc.html) | Exporter en CSV : période, comptes, brouillons et notes ; « Exporter » en bas | retenue | pas encore construit (prochaine étape) |
| [MontantsAutoA](MontantsAutoA.dc.html) | Automatique (d’office) | retenue | settings/long_amounts_sheet.dart |
| [MontantsJamais](MontantsJamais.dc.html) | Jamais | retenue | settings/long_amounts_sheet.dart |
| [MontantsReglage](MontantsReglage.dc.html) | Réglages › Montants longs (validé le 17 novembre) | validée le 17 novembre | settings/long_amounts_sheet.dart |
| [MontantsToujoursA](MontantsToujoursA.dc.html) | Toujours, dès 10 000 | retenue | settings/long_amounts_sheet.dart |
| [NoterKibuo](NoterKibuo.dc.html) | Noter Kibuo : une feuille, les étoiles, puis le Play Store | retenue | pas encore construit |
| [PinAttenteC2](PinAttenteC2.dc.html) | Après 5 codes faux : attendre | retenue | lock/unlock_screen.dart |
| [PinCreaC2](PinCreaC2.dc.html) | Créer le code (4 à 6 chiffres, puis « Valider ») | retenue | lock/create_pin_screen.dart |
| [PinEmpreinte](PinEmpreinte.dc.html) | Proposer l’empreinte, juste après le code | retenue | lock/protect_sheet.dart |
| [ProtectionCodeB](ProtectionCodeB.dc.html) | Puis le code, dans une feuille | retenue | lock/protect_sheet.dart |
| [Rappels](Rappels.dc.html) | Rappels | retenue | reminders/reminders_screen.dart |
| [RecupIllisible](RecupIllisible.dc.html) | Données illisibles · avec le code de récupération | retenue | lock/recovery_screens.dart |
| [RecupPreuve](RecupPreuve.dc.html) | Prouver qu’on a noté le code | retenue | lock/recovery_screens.dart |
| [RecupReglage](RecupReglage.dc.html) | Sécurité › Code de récupération | retenue | lock/recovery_screens.dart |
| [RecupSaisie](RecupSaisie.dc.html) | Saisir le code de récupération | retenue | lock/recovery_screens.dart |
| [ReglageDebutMois](ReglageDebutMois.dc.html) | Début du mois : une feuille sur Réglages, une roue qui défile, « Enregistrer » | retenue | settings/month_start_sheet.dart |
| [ReglageLangue](ReglageLangue.dc.html) | Langue : une feuille sur Réglages, liste qui défile, la langue choisie cochée | retenue | settings/language_sheet.dart |
| [Reglages](Reglages.dc.html) | Réglages | retenue | settings/settings_screen.dart |
| [ReglagesBrouillons](ReglagesBrouillons.dc.html) | Réglages › Récurrences et brouillons | retenue | recurrences/list_display.dart |
| [RegulFeuille](RegulFeuille.dc.html) | Enregistrer : la différence devient une opération | retenue | accounts/account_form_screen.dart |
| [RegulFormA](RegulFormA.dc.html) | « Solde actuel », un champ sous le nom | retenue | accounts/account_form_screen.dart |
| [RestauC1](RestauC1.dc.html) | Restaurer : la frise (gardé jusqu’à la sauvegarde, remplacé ensuite), le mot de passe, « Maintenir pour remplacer » | retenue | backup/restore_sheet.dart, kit/fields.dart, kit/hold_button.dart |
| [RestauC1Err](RestauC1Err.dc.html) | Restaurer : mauvais mot de passe | retenue | backup/restore_sheet.dart |
| [RestauC2](RestauC2.dc.html) | Restaurer : appui long en cours, la barre se remplit | retenue | backup/restore_sheet.dart |
| [RestauC3](RestauC3.dc.html) | Restaurer : c’est fait, ce qui est revenu et où est la copie d’avant | retenue | backup/restore_sheet.dart |
| [Sauvegarde](Sauvegarde.dc.html) | Sauvegarde | retenue | backup/backup_screen.dart |
| [SecuConfid](SecuConfid.dc.html) | Sécurité › Confidentialité | retenue | settings/security_screens.dart |
| [Securite](Securite.dc.html) | Sécurité | retenue | settings/security_screens.dart |
| [SigneD](SigneD.dc.html) | Solde actuel : maintenir « , » pour « − » (avec découvert seulement) | retenue | accounts/account_form_screen.dart, kit/keypad.dart |
| [TypeCompte](TypeCompte.dc.html) | Nouveau type de compte | retenue | accounts/account_type_screen.dart |
| [VerrouC2](VerrouC2.dc.html) | Déverrouiller | retenue | lock/unlock_screen.dart |
| [VerrouProtection](VerrouProtection.dc.html) | dans Verrouillage, seulement avec un code | retenue | settings/security_screens.dart |

### Dettes, projets et récurrences (5)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [DettesAffichage](DettesAffichage.dc.html) | Dettes : affichage des soldées | retenue | obligations/debts_screen.dart |
| [DettesCarteOuverte](DettesCarteOuverte.dc.html) | Dettes : une dette ouverte | retenue | obligations/debts_screen.dart |
| [NouvelleDette](NouvelleDette.dc.html) | Nouvelle dette | retenue | obligations/new_debt_screen.dart |
| [Recurrence](Recurrence.dc.html) | Nouvelle récurrence | retenue | recurrences/repeat_screen.dart |
| [RecurrencePetit](RecurrencePetit.dc.html) | Nouvelle récurrence, petit écran (340 px) | retenue | recurrences/repeat_screen.dart |

### Opérations (53)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [AffichageIcones](AffichageIcones.dc.html) | Affichage de la liste : brouillons et opérations prévues | retenue | recurrences/list_display.dart |
| [ApresFeuilleB](ApresFeuilleB.dc.html) | 10. Enregistrée : retour sur Opérations | retenue | kit/buttons.dart, kit/confirm_sheet.dart, transactions/entry_flow.dart |
| [ApresRevenu](ApresRevenu.dc.html) | 8. Enregistré : retour sur Opérations | retenue | transactions/entry_flow.dart |
| [ApresTransfert](ApresTransfert.dc.html) | 7. Enregistré : retour sur Opérations | retenue | transactions/entry_flow.dart |
| [BrouillonA3](BrouillonA3.dc.html) | Brouillons : à leur date, Ignorer ou Valider | retenue | kit/toast.dart, recurrences/list_display.dart, theme/kibuo_colors.dart |
| [DecouvertSaisieA](DecouvertSaisieA.dc.html) | Saisie refusée sous le plancher | retenue | transactions/overdraft_check.dart, kit/fields.dart |
| [DecouvertSuppressionA](DecouvertSuppressionA.dc.html) | Suppression refusée sous le plancher | retenue | transactions/overdraft_check.dart, operation_screens.dart |
| [DelConfirm](DelConfirm.dc.html) | Puis cette confirmation | retenue | transactions/operation_screens.dart |
| [EtatBarre](EtatBarre.dc.html) | Totaux : la barre se colore seulement en alerte | retenue | transactions/operations_list.dart |
| [FiltreMenuC](FiltreMenuC.dc.html) | Menu des filtres : les catégories du mois, les autres en feuille (validé le 17 novembre) | validée le 17 novembre | kit/choice_menu.dart |
| [FraisFeuille](FraisFeuille.dc.html) | 5. Frais supplémentaires, dans la devise du compte | retenue | transactions/entry_sheets.dart |
| [JoursRepliables](JoursRepliables.dc.html) | Liste : replier un jour, solde du jour sans les transferts | retenue | transactions/operations_list.dart |
| [ListeAnneePrec](ListeAnneePrec.dc.html) | 3. Dans le choix : année précédente | retenue | kit/month_picker.dart |
| [ListeFiltreOuvert](ListeFiltreOuvert.dc.html) | Filtre ouvert : Tous, nombres, coche ou point | retenue | kit/choice_menu.dart, transactions/operations_list.dart |
| [ListeMoisOuvert](ListeMoisOuvert.dc.html) | 2. Titre touché : choix flottant, année et 12 mois | retenue | kit/month_picker.dart |
| [ListeMoisPasse](ListeMoisPasse.dc.html) | 4. Après un glissement : octobre, « Ce mois-ci » pour revenir | retenue | transactions/operations_list.dart |
| [ListeOnboard](ListeOnboard.dc.html) | 1. Première visite : le geste montré, le fond en retrait | retenue | kit/month_picker.dart, transactions/operations_list.dart |
| [ListeOperations](ListeOperations.dc.html) | Liste du mois : totaux, filtres, lignes | retenue | transactions/operations_list.dart |
| [ListePetit](ListePetit.dc.html) | 5. Petit écran (340 px) | retenue | transactions/operations_list.dart |
| [OperationCarteBrouillon](OperationCarteBrouillon.dc.html) | Brouillon de récurrence, à valider | retenue | kit/operation_card.dart, theme/kibuo_colors.dart, transactions/draft_screen.dart |
| [OperationCarteIgnoree](OperationCarteIgnoree.dc.html) | Brouillon ignoré : on le valide depuis son détail | retenue | transactions/draft_screen.dart |
| [OperationCarteRevenu](OperationCarteRevenu.dc.html) | Revenu | retenue | transactions/operation_screens.dart |
| [OperationCarteTransfert](OperationCarteTransfert.dc.html) | Transfert | retenue | transactions/operation_screens.dart |
| [OperationCopieSaisie](OperationCopieSaisie.dc.html) | Dupliquer : la saisie, préremplie à la date du jour | retenue | transactions/entry_screen.dart |
| [OperationDetailBas](OperationDetailBas.dc.html) | Dépense | retenue | transactions/operation_screens.dart |
| [OperationEdition](OperationEdition.dc.html) | Modifier : la saisie, préremplie | retenue | transactions/entry_screen.dart |
| [PJLignes](PJLignes.dc.html) | 8. Pièces jointes : lignes avec aperçu, 5 au plus | retenue | transactions/attachments_card.dart |
| [PJSelBarre](PJSelBarre.dc.html) | 9. Pièces jointes : plusieurs choisies, barre en bas | retenue | transactions/attachments_card.dart |
| [PJVoirPdf](PJVoirPdf.dc.html) | Voir un PDF : la première page, « Ouvrir avec… » (une appli du téléphone) | retenue | transactions/attachment_viewer.dart |
| [PJVoirPhoto](PJVoirPhoto.dc.html) | Voir une photo : en grand, rien à modifier ici (on touche la pièce dans le détail ; à la saisie ou dans « Modifier », « | retenue | transactions/attachment_viewer.dart |
| [ParcoursDevise](ParcoursDevise.dc.html) | 2. Payé en francs : choisir la devise | retenue | transactions/entry_sheets.dart |
| [ParcoursFC](ParcoursFC.dc.html) | 3. Montant en francs, conversion en direct | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [ParcoursTaux](ParcoursTaux.dc.html) | 4. Au besoin, changer le taux | retenue | transactions/entry_sheets.dart |
| [ParcoursUSD](ParcoursUSD.dc.html) | 1. Dépense en dollars : clavier ouvert, « Terminé » le range | retenue | transactions/entry_screen.dart |
| [RechercheR2](RechercheR2.dc.html) | Recherche : tous les mois, le mois affiché d’abord | retenue | kit/empty_card.dart, transactions/search_screen.dart |
| [RecuTotal](RecuTotal.dc.html) | 7. Décompte replié sur le total | retenue | transactions/entry_screen.dart |
| [RegulListe](RegulListe.dc.html) | Dans la liste | retenue | transactions/operation_row.dart |
| [RevenuCategorie](RevenuCategorie.dc.html) | 6. Catégorie de revenu | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [RevenuDecompte](RevenuDecompte.dc.html) | 7. Décompte déroulé : ajouté au compte | retenue | transactions/entry_screen.dart |
| [RevenuDevise](RevenuDevise.dc.html) | 2. Reçu en francs : choisir la devise | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [RevenuFC](RevenuFC.dc.html) | 3. Montant en francs, conversion en direct | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [RevenuFrais](RevenuFrais.dc.html) | 5. Frais déduits, dans la devise du compte | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [RevenuTaux](RevenuTaux.dc.html) | 4. Au besoin, changer le taux | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [RevenuUSD](RevenuUSD.dc.html) | 1. Revenu en dollars : clavier ouvert | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [SaisieCategorie](SaisieCategorie.dc.html) | 6. Choisir la catégorie (ou toute la catégorie) | retenue | transactions/entry_sheets.dart |
| [TransfertDecompte](TransfertDecompte.dc.html) | 6. Décompte déroulé : retiré et arrivé | retenue | transactions/entry_screen.dart |
| [TransfertDevise](TransfertDevise.dc.html) | 3. Vers un compte en francs : conversion | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [TransfertFrais](TransfertFrais.dc.html) | 5. Frais, dans la devise du compte de départ | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [TransfertMeme](TransfertMeme.dc.html) | 1. Entre deux comptes en dollars | retenue | theme/kibuo_colors.dart, transactions/entry_screen.dart |
| [TransfertTaux](TransfertTaux.dc.html) | 4. Au besoin, changer le taux | retenue | transactions/entry_screen.dart, entry_sheets.dart |
| [TransfertVers](TransfertVers.dc.html) | 2. Choisir le compte d’arrivée | retenue | transactions/entry_sheets.dart |
| [VideB](VideB.dc.html) | B · une feuille explique avant la saisie : « D’abord, un compte » | retenue | transactions/entry_flow.dart |
| [VideSobre](VideSobre.dc.html) | Liste vide : pointillés gris, l’action utile | retenue | kit/empty_card.dart |

### Aperçu (27)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [ApercuP2](ApercuP2.dc.html) | Retenu · ‹ période › à droite du titre, onglets Évolution, Catégories, Patrimoine | validée (date à vérifier) | `lib/ui/overview/overview_screen.dart` |
| [ApercuP2Ouvert](ApercuP2Ouvert.dc.html) | Retenu · la période touchée : période, regroupement, comparaison | validée (date à vérifier) | `lib/ui/overview/period_sheet.dart` |
| [ApercuTAn](ApercuTAn.dc.html) | Points suivis · 1 an : épargne, moyenne par mois, patrimoine | retenue | `lib/ui/overview/followed_section.dart` |
| [ApercuTJour](ApercuTJour.dc.html) | Points suivis · Aujourd’hui : comparé à une journée moyenne, ce qui reste, ce qui arrive | retenue | `lib/ui/overview/followed_section.dart` |
| [ApercuTMois](ApercuTMois.dc.html) | Points suivis · 1 mois : 4 tuiles, « Voir les 4 autres » déplie le reste | retenue | `lib/ui/overview/followed_section.dart` |
| [ApercuTPerso](ApercuTPerso.dc.html) | Points suivis · période personnalisée (73 jours) : se règle sur sa longueur | retenue | `lib/ui/overview/followed_section.dart` |
| [ApercuTSuivre](ApercuTSuivre.dc.html) | Points suivis · « Suivre » : choisir ses tuiles, dont celles de l’écran 4 | retenue | `lib/ui/overview/follow_sheet.dart` |
| [ApercuTuile](ApercuTuile.dc.html) | Une tuile agrandie : carte au centre, fond flouté, la suivante dépasse | retenue | `lib/ui/overview/enlarged_tiles.dart`, `lib/ui/overview/enlarged_parts.dart` |
| [TuileDepenseA](TuileDepenseA.dc.html) | Tuile agrandie · Dépensé : courbes cumulées, trait du jour, repères en lignes | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileDepenseA3-cas1](TuileDepenseA3-cas1.dc.html) | Dépensé · le trait du jour le 30, au bord droit | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileDepenseA3-cas2](TuileDepenseA3-cas2.dc.html) | Dépensé · le trait du jour le 2, en bas à gauche | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileRecuA](TuileRecuA.dc.html) | Tuile agrandie · Reçu : courbes cumulées, repères en lignes | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileRecuR3](TuileRecuR3.dc.html) | « Suivre » · carte Affichage : Dépensé, Reçu et Épargne en Courbe ou Bâtonnets | validée le 27 novembre 2026 | `lib/ui/overview/follow_sheet.dart` |
| [TuileEpargneE3](TuileEpargneE3.dc.html) | Tuile agrandie · Épargne : courbe et zéro, pastille « 27 % gardés » | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileMoyenneA](TuileMoyenneA.dc.html) | Tuile agrandie · Moyenne : barres par jour, moyenne en pointillé | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileCategorieA](TuileCategorieA.dc.html) | Tuile agrandie · Catégorie n° 1 : les trois premières en barres | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuilePlusCherK2](TuilePlusCherK2.dc.html) | Tuile agrandie · Jour le plus cher : le mois en calendrier, montants dans les cases | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuilePlusCherK2-jour](TuilePlusCherK2-jour.dc.html) | Jour le plus cher sur un jour : les 24 heures | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuilePlusCherK2-semaine](TuilePlusCherK2-semaine.dc.html) | Jour le plus cher sur une semaine : les 7 jours | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuilePlusCherK2-annee](TuilePlusCherK2-annee.dc.html) | Mois le plus cher sur une année : une case par mois | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileAVenirAB](TuileAVenirAB.dc.html) | Tuile agrandie · À venir : ruban des 14 jours, liste datée | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileBudgetAB](TuileBudgetAB.dc.html) | Tuile agrandie · Un budget : au fil du mois, repères en lignes | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileDettesAC](TuileDettesAC.dc.html) | Tuile agrandie · Dettes : barre du remboursé, date d’échéance en carré gris | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileCreancesAC](TuileCreancesAC.dc.html) | Tuile agrandie · Créances : comme Dettes, en vert | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileProjetA](TuileProjetA.dc.html) | Tuile agrandie · Un projet : barre et repère du plan | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuileComptesB](TuileComptesB.dc.html) | Tuile agrandie · Comptes : barre découpée par compte | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |
| [TuilePatrimoineA](TuilePatrimoineA.dc.html) | Tuile agrandie · Patrimoine net : en cascade | validée le 27 novembre 2026 | `lib/ui/overview/enlarged_tiles.dart` |

### Budgets (7)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [BudgetDetail](BudgetDetail.dc.html) | Un budget : bilan, graphique « Total », opérations par jour | retenue | budgets/budget_chart.dart, budgets/budget_detail_screen.dart, kit/day_header.dart |
| [BudgetJourReplie](BudgetJourReplie.dc.html) | Un budget : un jour replié dans la liste | retenue | budgets/budget_detail_screen.dart |
| [BudgetNouveau](BudgetNouveau.dc.html) | Nouveau budget : montant avec la moyenne, catégorie, période, alertes | retenue | budgets/budget_form_screen.dart |
| [BudgetRythme](BudgetRythme.dc.html) | Un budget : graphique sur « Rythme » | retenue | budgets/budget_chart.dart, budgets/budget_detail_screen.dart |
| [Budgets](Budgets.dc.html) | Budgets : tuiles par défaut, bilan du mois, trait du jour | retenue | budgets/budgets_screen.dart |
| [BudgetsAffichage](BudgetsAffichage.dc.html) | « Affichage des budgets » : disposition et ordre | retenue | budgets/budgets_screen.dart |
| [BudgetsListe](BudgetsListe.dc.html) | Budgets en liste, groupée par état | retenue | budgets/budgets_screen.dart |

### Projets (11)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [FicheProjet](FicheProjet.dc.html) | Un projet : bilan, « Mettre de côté », le plan (par semaine), versements | retenue | projects/project_screen.dart |
| [FicheProjetMois](FicheProjetMois.dc.html) | Le plan par mois | retenue | projects/project_screen.dart |
| [FicheProjetQuinzaine](FicheProjetQuinzaine.dc.html) | Le plan par quinzaine | retenue | projects/project_screen.dart |
| [FicheProjetSansDate](FicheProjetSansDate.dc.html) | Sans date : « À votre rythme », pas de plan, un versement repris en gris | retenue | projects/project_screen.dart |
| [ProjetAtteint](ProjetAtteint.dc.html) | Objectif atteint : dépensé, gardé, ou rendu disponible | retenue | projects/project_money.dart |
| [ProjetMettreRefus](ProjetMettreRefus.dc.html) | Mettre de côté depuis un autre compte : transfert annoncé, refus au-delà du libre | retenue | projects/project_money.dart |
| [ProjetNouveau](ProjetNouveau.dc.html) | Nouveau projet : nom et icône, objectif, compte, date, division du plan, rappel | retenue | projects/new_project_screen.dart |
| [ProjetReprendre](ProjetReprendre.dc.html) | Reprendre de l’argent : « Tout », aucune opération | retenue | projects/project_money.dart |
| [ProjetSupprimer](ProjetSupprimer.dc.html) | Supprimer : la confirmation | retenue | projects/project_screen.dart |
| [ProjetTermine](ProjetTermine.dc.html) | Projet terminé : lecture seule, « Supprimer le projet » | retenue | projects/project_screen.dart |
| [Projets](Projets.dc.html) | Projets : bilan, une carte par projet, trait « où vous devriez en être » | retenue | projects/projects_screen.dart |

### En cours (16)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [ConfirmA](ConfirmA.dc.html) | A · Feuille qui se ferme seule, avec actions | validée le 23 novembre | kit/buttons.dart, kit/confirm_sheet.dart, obligations/debt_screen.dart |
| [ConfirmB](ConfirmB.dc.html) | B · Message plus grand, posé en bas | écartée | — |
| [OpDetteA](OpDetteA.dc.html) | A · Étiquette | écartée | — |
| [OpDetteA1](OpDetteA1.dc.html) | A1 · Fond teinté léger | écartée | — |
| [OpDetteA2](OpDetteA2.dc.html) | A2 · Fond teinté, tuile blanche | écartée | — |
| [OpDetteA3](OpDetteA3.dc.html) | A3 · Fond teinté, fin contour | écartée | — |
| [OpDetteA4](OpDetteA4.dc.html) | A4 · Fin contour seul | validée le 23 novembre | categories/category_labels.dart, transactions/operation_row.dart |
| [OpDetteB](OpDetteB.dc.html) | B · Pointillés, montant gris | écartée | — |
| [OpDetteC](OpDetteC.dc.html) | C · Montant entouré | écartée | — |
| [RecurrenceFiche](RecurrenceFiche.dc.html) | La fiche d’une récurrence : prochaines fois, dernières fois, Arrêter | retenue | recurrences/recurrences_screen.dart |
| [RecurrencesA](RecurrencesA.dc.html) | A · retenue : Récurrences groupées par type | retenue | recurrences/recurrences_screen.dart |
| [RecurrencesB](RecurrencesB.dc.html) | B · non retenue | écartée | — |
| [RepeterA](RepeterA.dc.html) | A · retenue : une ligne « Répéter » qui ouvre Nouvelle récurrence | retenue | transactions/entry_screen.dart |
| [RepeterB](RepeterB.dc.html) | B · non retenue | écartée | — |
| [RepeterC](RepeterC.dc.html) | C · non retenue | écartée | — |
| [Suivi](Suivi.dc.html) | Suivi : les étapes en attente | suivi de travail | — |

### Sans page (variantes écartées) (36)

| Fichier | Écran | État | Code (`lib/ui/`) |
|---|---|---|---|
| [BarreIconesA](BarreIconesA.dc.html) | — | écartée | — |
| [BarreIconesB](BarreIconesB.dc.html) | — | écartée | — |
| [BarreIconesC](BarreIconesC.dc.html) | — | écartée | — |
| [CentimesA](CentimesA.dc.html) | — | écartée | — |
| [CentimesB](CentimesB.dc.html) | — | écartée | — |
| [CompteModifB](CompteModifB.dc.html) | — | écartée | — |
| [DelA](DelA.dc.html) | — | écartée | — |
| [DelB](DelB.dc.html) | — | écartée | — |
| [DelaiA](DelaiA.dc.html) | — | écartée | — |
| [DelaiC](DelaiC.dc.html) | — | écartée | — |
| [EditDevA](EditDevA.dc.html) | — | écartée | — |
| [EditDevB](EditDevB.dc.html) | — | écartée | — |
| [LogoCentrage](LogoCentrage.dc.html) | — | écartée | — |
| [PinAttente](PinAttente.dc.html) | — | écartée | — |
| [PinCreaA](PinCreaA.dc.html) | — | écartée | — |
| [PinCreaB](PinCreaB.dc.html) | — | écartée | — |
| [PinCreaC](PinCreaC.dc.html) | — | écartée | — |
| [PinCreaC1](PinCreaC1.dc.html) | — | écartée | — |
| [PinCreaC3](PinCreaC3.dc.html) | — | écartée | — |
| [RegulFormB](RegulFormB.dc.html) | — | écartée | — |
| [SecuOptA](SecuOptA.dc.html) | — | écartée | — |
| [SecuOptB](SecuOptB.dc.html) | — | écartée | — |
| [SecuOptC](SecuOptC.dc.html) | — | écartée | — |
| [SecuProtection](SecuProtection.dc.html) | — | écartée | — |
| [SecuProtectionSansCode](SecuProtectionSansCode.dc.html) | — | écartée | — |
| [SecuVerrou](SecuVerrou.dc.html) | — | écartée | — |
| [SigneA](SigneA.dc.html) | — | écartée | — |
| [SigneB](SigneB.dc.html) | — | écartée | — |
| [SigneC](SigneC.dc.html) | — | écartée | — |
| [SplitA1](SplitA1.dc.html) | — | écartée | — |
| [SplitA2](SplitA2.dc.html) | — | écartée | — |
| [SplitB1](SplitB1.dc.html) | — | écartée | — |
| [SplitB2](SplitB2.dc.html) | — | écartée | — |
| [Verrou](Verrou.dc.html) | — | écartée | — |
| [VideA](VideA.dc.html) | — | écartée | — |
| [VideC](VideC.dc.html) | — | écartée | — |
