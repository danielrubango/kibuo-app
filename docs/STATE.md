# État du projet

Photographie au **25 novembre 2026**, branche `main` (dernière fusion : `feat/launch-auto-backup`). À tenir à jour à chaque fusion. Les cases de la roadmap sont dans [ROADMAP.md](ROADMAP.md) ; ce qui suit ajoute les dates, ce qui reste ouvert et les pièges connus.

## Livré

Toutes les phases sont livrées sur `main` et validées par le propriétaire, phase par phase. Dates de fusion d'après `git log --merges --first-parent main`.

| Phase | Ce qui est livré | Fusionné |
|---|---|---|
| 0 · Fondations | Cadrage, nom, dépôt, documentation | avant le 15 nov. |
| 1 · Identité et design | Logo, icône Android, direction visuelle, toutes les maquettes de la V1 (canvas) | avant le 15 nov. ; démarrage animé le 17 nov. |
| 2 · Socle technique | Thème, navigation et +, français/anglais, base chiffrée (SQLCipher par SQLite3 Multiple Ciphers) et migrations, verrouillage PIN/biométrie, confidentialité, code de récupération | 15 nov. |
| 3 · Cœur | Devises et taux, comptes, catégories, dépenses et revenus, pièces jointes, transferts, découvert, régularisation, actions protégées, saisie rapide, liste et recherche des opérations, premier lancement, accueil, montants courts | 15 au 17 nov. |
| 4 · Planification | Début du mois, budgets et leur détail, récurrences et brouillons, retouches, rappels (saisie, échéances, opérations datées plus tard, solde insuffisant), alertes de budget, fiche d'une opération prévue | 17 au 19 nov. |
| 5 · Dettes, créances, projets | Dettes et créances en trois livraisons (liste, fiche et remboursements, autour : cartes de l'accueil, À traiter, rappels, réclamer), cartes de l'accueil aux marges unifiées, projets en trois livraisons (créer et lister ; fiche, mettre de côté, reprendre, objectif atteint, modifier, supprimer ; À traiter, rappels au rythme du plan, réservé dans Comptes) | 23 et 24 nov. |
| 6 · Données (en partie) | Sauvegarde manuelle (fichier `.kibuo`, ADR 0012), lignes de réglages corrigées, nettoyage du kit (`context.money`, `calendarDays`, `IconTile`), restauration en deux livraisons (depuis l'écran Sauvegarde ; « J'ai une sauvegarde » au premier lancement et sur les données illisibles ; ouverture d'un fichier `.kibuo` touché ailleurs ; la langue voyage dans le fichier), sauvegardes automatiques, première livraison sur trois (interrupteur de l'écran Sauvegarde, sauvegarde à l'ouverture et en arrière-plan chaque semaine, 4 gardées, échecs signalés une fois par semaine) ; mot de passe retenu (variante A : ligne « Mot de passe » de l'écran Sauvegarde, sa feuille, la feuille manuelle « Chiffrée avec votre mot de passe », restauration qui l'essaie d'abord, copie d'avant restauration chiffrée) ; feuilles à 8 au-dessus du clavier ; « Sauvegardes automatiques » à l'étape 4 du premier lancement (variante 3 A) | 24 et 25 nov. |

Schéma de la base : **version 14** (`KibuoDatabase.currentSchema`). 713 tests verts à la dernière fusion.

## Dessiné mais pas encore construit

Validés sur le canvas, absents de l'app : la page **Plus** (l'onglet montre une liste provisoire de lignes : comptes, budgets, dettes, projets, récurrences, catégories, types, devises, début du mois, montants longs, rappels, sécurité, sauvegarde), la page **Réglages** et le choix de la langue après le premier lancement, l'**Aperçu** (écran d'attente, phase 7 « Tableaux de bord »), l'**export CSV**, Aide et support, À propos, Noter kibuo. Liste des planches : [design/DIRECTION.md](design/DIRECTION.md#écrans-livrés-et-leur-planche).

## En cours ou non fusionné

- Aucune branche de code en attente : toutes sont fusionnées dans `main`.
- Sur l'émulateur : un utilisateur Android d'essai `kibuo-essai` (id 10), arrêté. Ses données de test ont été effacées le 25 novembre (accord du propriétaire) pour rejouer le premier lancement : il a maintenant un compte « Essai » et la sauvegarde automatique dans Download/Kibuo. Gardé jusqu'à la fin de la phase 6 (voir [WORKING.md](WORKING.md)).

## Prochaines étapes

1. **Export CSV** (phase 6) : planche `ExportCSV` (période, comptes, brouillons et notes, « Exporter » en bas).
2. **Phase 7 · Stabilisation** : tableaux de bord, premier lancement revu ([backlog/premier-lancement.md](backlog/premier-lancement.md)), parcours complets sur le Poco X3 NFC et un Android 8, guide des notifications selon les marques, APK à 5 à 10 testeurs.
3. Reste de la phase 1 : vérifier les marques et réserver les domaines ([BRAND.md](BRAND.md)).

## Décisions récentes

Toutes les décisions prises avec le propriétaire jusqu'au 24 novembre sont écrites à leur place : [PRODUCT.md](PRODUCT.md) (comportements, avec leur date), [design/DIRECTION.md](design/DIRECTION.md) (règles visuelles), [adr/](adr/) (décisions structurantes). Les dernières :

- Restauration : PRODUCT, sections « Restauration » et « Au départ » ; bouton de fin « Voir mes données ».
- La langue voyage dans le fichier de sauvegarde : [ADR 0012](adr/0012-format-du-fichier-de-sauvegarde.md).
- Lignes de réglages, barres dans une carte, actions sous une carte, liens en fin de carte, confirmations des mouvements d'argent : DIRECTION.
- Les planches du canvas sont désormais aussi dans le dépôt ([design/boards/](design/boards/)), le 24 novembre (le choix du matin même était de les garder dans le canvas seulement).
- Les règles des agents vivent dans `AGENTS.md`, que `CLAUDE.md` importe.

## Questions ouvertes (attendent le propriétaire)

- Aucune pour l'instant (l'échec d'une sauvegarde automatique est tranché le 24 novembre : PRODUCT, Protection des données).

## Défauts connus et dettes

- **Pas vu sur un vrai téléphone** : ouvrir kibuo en touchant un `.kibuo` dans Fichiers ou WhatsApp (simulé sur l'émulateur par une intention `VIEW`, à vérifier sur le Poco X3).
- **Vu seulement par les tests** : le code des actions importantes pour changer ou retirer le mot de passe des sauvegardes ; une restauration qui ouvre une sauvegarde chiffrée avec le mot de passe retenu sans le demander, et la copie d'avant chiffrée ; la langue rendue par une restauration ; la feuille de départ avec une sauvegarde chiffrée ; « J'ai une sauvegarde » sur l'écran des données illisibles ; une sauvegarde automatique due faite kibuo fermé (la sauvegarde à l'ouverture a, elle, été vue le 25 novembre sur le profil d'essai), et sa notification d'échec (l'émulateur refuse d'avancer l'horloge par adb ; le moteur de fond a été lancé et s'arrête proprement quand rien n'est dû).
- **À surveiller sur le Poco X3** : que la tâche de fond de Xiaomi produise bien un `kibuo-auto-…` au bout d'une semaine sans ouvrir kibuo (installé le 24 novembre).
- Le message en bas de l'écran garde la coche menthe même pour un échec (sauvegarde manuelle et automatique) : une icône d'alerte serait plus juste, écart au kit à proposer.
- Les sauvegardes faites avant le 24 novembre (soir) ne portent pas la langue.
- Un interrupteur ne réagit que sur lui-même, pas sur toute sa ligne (partout ; décidé le 24 novembre que toute la ligne réagira, à construire).
- Si kibuo est fermé pendant que le code de récupération est affiché, le code n'a jamais été confirmé.
- Les groupes de comptes repliés ne sont pas retenus ; un compte archivé ne peut pas être rétabli.
- Un « Enregistrer » grisé ne dit pas ce qui manque (décidé le 24 novembre : bouton actif et premier champ manquant en rouge, planches à montrer, puis à construire).
- 36 des 258 planches du canvas ne sont rattachées à aucune page : variantes écartées, classées dans [DIRECTION.md](design/DIRECTION.md#variantes-écartées-et-pourquoi), souvent sans raison écrite.
- La planche P1 du chiffrement de sauvegarde (`sauvegarde-variantes.html`) n'est ni dans le canvas exporté ni dans le dépôt.
- iOS : chaque API propre à Android est notée dans [backlog/ios.md](backlog/ios.md) ; rien n'est porté.

## Pièges rencontrés et leur solution

### Émulateur et Android

- **Émulateur saturé** (ANR, écran de démarrage figé, une capture qui prend une minute) : le redémarrer. `adb -s emulator-5554 emu kill`, puis `~/Library/Android/sdk/emulator/emulator -avd Pixel_10_Kibuo -no-snapshot-save &`, attendre `getprop sys.boot_completed` = 1. Deux utilisateurs Android actifs à la fois suffisent à le saturer : arrêter l'utilisateur d'essai après usage (`am stop-user 10`).
- **Après `install -r`, l'app rouvre l'écran où elle était** : prendre une capture avant de toucher, les coordonnées d'un écran ne valent pas pour un autre.
- **Utilisateur d'essai derrière l'écran de verrouillage** (capture noire, focus sur `NotificationShade`) : `adb shell input keyevent 224`, `wm dismiss-keyguard`, `input keyevent 82`, puis un glissement vers le haut.
- **Déposer un fichier chez l'utilisateur d'essai** : `adb push` vers `/storage/emulated/10/` est refusé. Pousser dans `/data/local/tmp/`, `chmod 644`, puis l'ouvrir dans kibuo : `adb shell am start --user 10 -a android.intent.action.VIEW -d file:///data/local/tmp/x.kibuo -t application/octet-stream -n app.kibuo/.MainActivity`.
- **Langue sur Android 13+** : la langue choisie est gardée par Android (`setAndroidAppLanguage`), pas dans la base ; d'où sa présence dans le résumé du fichier de sauvegarde.
- **Lancer la sauvegarde de fond à la main** : `adb shell cmd jobscheduler run -f -n androidx.work.systemjobscheduler app.kibuo <id>` (l'id se lit dans `dumpsys jobscheduler`, ligne `#AutoBackupWorker#`). Avant l'échéance, WorkManager la repousse (« executed before schedule ») ; éteindre puis rallumer l'interrupteur la relance aussitôt. `cmd time_detector suggest_manual_time` est refusé au shell : on ne peut pas avancer l'horloge par adb.
- **Coordonnées adb** : les captures sont réduites à 540 de large (×2 environ pour taper) ; avec deux appareils branchés, toujours `-s`.

### Base chiffrée (SQLite3 Multiple Ciphers)

- La clé est en hexadécimal brut : `PRAGMA hexkey = '…'` à l'ouverture.
- **Copier la base en clair** sans toucher au fichier : `VACUUM INTO 'copie'`, puis `ATTACH 'copie' AS c` (elle hérite de la clé) et `PRAGMA c.rekey = ''`.
- **Chiffrer une copie en clair** avec la clé du téléphone : l'ouvrir sans clé, `PRAGMA hexrekey = '<clé>'` (voir `replaceWithBackup` dans `lib/data/open_database.dart`).
- Une base d'un autre téléphone, ou dont la clé a disparu, s'ouvre en erreur « not a database » : c'est l'état `Unreadable`, le fichier est mis de côté, jamais effacé.
- **Migrations** : monter `KibuoDatabase.currentSchema`, `dart run build_runner build`, `dart run drift_dev make-migrations`, écrire le test contre les schémas sauvés (`test/drift/kibuo/`) et le voir échouer, puis ajouter l'étape `fromXToY`. Une base v11 venue d'une branche abandonnée (`codex/debts-receivables`) est réparée au démarrage (`_repairDebts`).

### Tests

- **Les vraies entrées-sorties bloquent les tests de widgets** : fichiers en mémoire (`MemoryFiles`), faux canaux ; quand il faut du vrai disque ou un isolate (sauvegarde, restauration), boucler `tester.runAsync(() => Future.delayed(…))` puis `tester.pump(…)` plusieurs fois (voir `settle` dans `test/restore_sheet_test.dart`).
- **Une feuille qui se ferme seule** (confirmation avec barre) : `pumpAndSettle` attend qu'elle se ferme ; pour la voir, pomper par petits pas (`soft` dans `test/project_card_test.dart`).
- **Une animation en boucle** bloque `pumpAndSettle` : pomper par durée.
- **Appui long** (`HoldToConfirm`) : `startGesture`, puis un `pump()` vide (le remplissage commence à l'image suivante), puis des `pump(durée)` qui dépassent la durée totale.
- **Montants** : les espaces fines insécables (U+202F, U+00A0) de `formatMoney` ; comparer avec un `plain()` qui les remplace.
- **Dates** : les données de test datées « aujourd'hui » à minuit (voir WORKING).
- Un canal natif absent en test lève `MissingPluginException` : l'attraper dans l'adaptateur (voir `DeviceBackupFiles.takeOpened`).

### Interface (Flutter)

- Un enfant non positionné dans une `Stack` sans largeur imposée prend une largeur nulle : envelopper dans `Positioned(left: 0, right: 0, …)`.
- Pour aligner un texte à droite dans une `Row`, `Flexible` ne suffit pas (il prend sa largeur naturelle) : `Expanded` avec `textAlign: TextAlign.right`.
- Les widgets hérités posés dans la route d'accueil (`KibuoData`, `KibuoRestore`) ne sont pas visibles depuis une route poussée par-dessus : les lire dans `AppShell` et les passer en paramètre.
- Les feuilles s'ouvrent au-dessus de l'écran de verrouillage : ne rien ouvrir tant que kibuo est verrouillé (voir `_openedFile` dans `lib/ui/shell/app_shell.dart`).
- Après un remplacement de la base, l'app se reconstruit grâce à une `KeyedSubtree` sur la base ouverte (`DataGate`).
