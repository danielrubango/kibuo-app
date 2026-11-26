# État du projet

Photographie au **25 novembre 2026**, branche `main` (dernière fusion : `chore/release-signing`). À tenir à jour à chaque fusion. Les cases de la roadmap sont dans [ROADMAP.md](ROADMAP.md) ; ce qui suit ajoute les dates, ce qui reste ouvert et les pièges connus.

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

| 0.1 · Première publication (en cours) | Page Plus (Mes espaces avec leurs chiffres, Réglages, Sauvegarde et export, À propos de kibuo), page Réglages en quatre sections (Comptes et Catégories restés dans Plus), choix de la langue, le verrou qui couvre tous les écrans et feuilles (et code des actions importantes demandé partout), À propos (version et date, politique de confidentialité dans l'app, licences, « Nous écrire » vers contact@kibuo.app), mesure d'usage anonyme avec accord (feuille « Aider à améliorer kibuo ? », interrupteur dans Confidentialité, envoi par kibuo lui-même à PostHog Europe, ADR 0013), « Dollar américain », écran d'attente de l'Aperçu (variante B : ce qui vient, et « En attendant »), « Enregistrer » qui dit ce qui manque (champ souligné ou entouré de rouge, en douceur ; chaque onglet de la saisie retient son choix) | 25 nov. |

Schéma de la base : **version 14** (`KibuoDatabase.currentSchema`). 561 tests verts à la dernière fusion, après le tri des tests du 25 novembre (766 avant ; règle dans AGENTS.md et WORKING.md).

## Dessiné mais pas encore construit

Validés sur le canvas, absents de l'app : l'**Aperçu** et ses graphiques (version 0.2 ; un écran d'attente les annonce), l'**export CSV** (0.3), Aide et support (0.5), Noter kibuo (après la publication), et sur À propos, Conditions d'utilisation et Site web (avec le site public). Liste des planches : [design/DIRECTION.md](design/DIRECTION.md#écrans-livrés-et-leur-planche).

## En cours ou non fusionné

- Aucune branche de code en attente : toutes sont fusionnées dans `main`.
- Sur l'émulateur : plus d'utilisateur d'essai (`kibuo-essai` supprimé le 25 novembre, accord du propriétaire, pour libérer l'émulateur) ; s'il bloque encore après un redémarrage, il peut être réinitialisé.

## Prochaines étapes

Le plan a été réorganisé le 25 novembre 2026 pour publier tôt : une version **0.1** sur Google Play, puis une nouveauté par version (0.2 Aperçu, 0.3 export CSV et partage d'une sauvegarde, 0.4 thème sombre, 0.5 accompagnement), et la **1.0** stable après quelques semaines de test. Le détail et l'ordre des grands chantiers d'après (cloud, IA, iOS…) sont dans [ROADMAP.md](ROADMAP.md).

Prochaine case : **version 0.1, vérifier la marque « kibuo » et réserver le domaine** (BRAND : recherches OMPI, EUIPO, INPI ; `kibuo.app` acheté par le propriétaire le 26 novembre, `kibuo.com` à décider ; puis la boîte contact@kibuo.app). Page de confidentialité (26 novembre) : variante C1 validée, pages française et anglaise dans `kibuo-api/site/` (fusionnées dans `main` du dépôt du site le 26 novembre), texte de l'appli aligné ; en ligne sur Cloudflare Pages le 26 novembre ; pages déplacées sous `/fr/` et `/en/` avec un sommaire qui suit la lecture (validé et fusionné le 26 novembre) ; case « Site public » cochée ; la page du site dit aussi que l'hébergeur compte les visites (« Ce site ») , et contact@kibuo.app reçoit le courrier (routage Cloudflare, 26 novembre) ([backlog/site-public.md](backlog/site-public.md)). Le nom (`v0.1.0`) et la note de publication de la 0.1.0 sont validés ([releases/0.1.0.md](releases/0.1.0.md), 26 novembre). Le paquet AAB est signé avec la clé d'importation du propriétaire depuis le 25 novembre ([backlog/google-play.md](backlog/google-play.md)). Point ouvert : une app de budget exige-t-elle un compte d'organisation (« produits et services financiers ») ? À voir dans la Play Console avant de payer. Fiche Google Play en cours (26 novembre, [backlog/fiche-google-play.md](backlog/fiche-google-play.md)) : nom « kibuo : budget et épargne », brève description, description complète en français et en anglais, et six captures au style A validés ; image de présentation (variante B) et icône en 512 × 512 faites le même jour (`tool/play_graphics.py`) ; restent le formulaire sur la sécurité des données et la classification du contenu, à remplir dans la Play Console. Les captures se refont avec `tool/demo_backup_test.dart` puis `tool/play_screens.py`. Dans les onglets des dettes, un montant approché s'écrit « ~202 500 FC » (DIRECTION, 26 novembre). Test fermé (26 novembre) : paquet `v0.1.0-alpha-2` (version `0.1.0-alpha-2+2`, affichée dans À propos) construit (région des statistiques, « ~ », cadre de la visite guidée) ; nom et note de chaque paquet validés avant de construire l'AAB ([releases/](releases/README.md)) ; posts de la semaine A et C prêts ; invitation WhatsApp validée, testeurs ajoutés par adresse e-mail ([backlog/test-ferme.md](backlog/test-ferme.md)). Tontines et feuille de route en ligne notées dans la ROADMAP.

## Décisions récentes

Toutes les décisions prises avec le propriétaire jusqu'au 24 novembre sont écrites à leur place : [PRODUCT.md](PRODUCT.md) (comportements, avec leur date), [design/DIRECTION.md](design/DIRECTION.md) (règles visuelles), [adr/](adr/) (décisions structurantes). Les dernières :

- Restauration : PRODUCT, sections « Restauration » et « Au départ » ; bouton de fin « Voir mes données ».
- La langue voyage dans le fichier de sauvegarde : [ADR 0012](adr/0012-format-du-fichier-de-sauvegarde.md).
- Lignes de réglages, barres dans une carte, actions sous une carte, liens en fin de carte, confirmations des mouvements d'argent : DIRECTION.
- Les planches du canvas sont désormais aussi dans le dépôt ([design/boards/](design/boards/)), le 24 novembre (le choix du matin même était de les garder dans le canvas seulement).
- Les règles des agents vivent dans `AGENTS.md`, que `CLAUDE.md` importe.
- Le plan de publication (0.1 sur Google Play, 0.2 à 0.5, puis 1.0 stable) : [ROADMAP.md](ROADMAP.md), 25 novembre.
- Plus, Réglages (Comptes et Catégories restés dans Plus), À propos et sa politique de confidentialité : PRODUCT, 25 novembre.
- La mesure d'usage anonyme et les erreurs, avec accord, dans la 0.1 : [ADR 0013](adr/0013-mesure-d-usage-anonyme.md), 25 novembre.
- La fenêtre des guides garde la même marge de 8 de chaque côté et entoure toute la carte du groupe montré ; la fenêtre et la carte du guide sont dans le kit (`GuideSpotlight`, `GuideCard`) : DIRECTION, « Guides », 26 novembre.

## Questions ouvertes (attendent le propriétaire)

- Aucune pour l'instant (l'échec d'une sauvegarde automatique est tranché le 24 novembre : PRODUCT, Protection des données).

## Défauts connus et dettes

- **Pas vu sur un vrai téléphone** : ouvrir kibuo en touchant un `.kibuo` dans Fichiers ou WhatsApp (simulé sur l'émulateur par une intention `VIEW`, à vérifier sur le Poco X3).
- **Vu seulement par les tests** : le code des actions importantes pour changer ou retirer le mot de passe des sauvegardes ; une restauration qui ouvre une sauvegarde chiffrée avec le mot de passe retenu sans le demander, et la copie d'avant chiffrée ; la langue rendue par une restauration ; la feuille de départ avec une sauvegarde chiffrée ; « J'ai une sauvegarde » sur l'écran des données illisibles ; une sauvegarde automatique due faite kibuo fermé (la sauvegarde à l'ouverture a, elle, été vue le 25 novembre sur le profil d'essai), et sa notification d'échec (l'émulateur refuse d'avancer l'horloge par adb ; le moteur de fond a été lancé et s'arrête proprement quand rien n'est dû).
- **À surveiller sur le Poco X3** : que la tâche de fond de Xiaomi produise bien un `kibuo-auto-…` au bout d'une semaine sans ouvrir kibuo (installé le 24 novembre).
- **À confirmer par le propriétaire** : le texte de la politique de confidentialité (rédigé le 25 novembre, à relire), et l'aide de la langue réduite à « Les nombres et les dates suivent la langue. ».
- Le message en bas de l'écran garde la coche menthe même pour un échec (sauvegarde manuelle et automatique) : une icône d'alerte serait plus juste, écart au kit à proposer.
- Les sauvegardes faites avant le 24 novembre (soir) ne portent pas la langue.
- Si kibuo est fermé pendant que le code de récupération est affiché, le code n'a jamais été confirmé.
- Les groupes de comptes repliés ne sont pas retenus ; un compte archivé ne peut pas être rétabli.
- 36 des 258 planches du canvas ne sont rattachées à aucune page : variantes écartées, classées dans [DIRECTION.md](design/DIRECTION.md#variantes-écartées-et-pourquoi), souvent sans raison écrite.
- La planche P1 du chiffrement de sauvegarde (`sauvegarde-variantes.html`) n'est ni dans le canvas exporté ni dans le dépôt.
- iOS : chaque API propre à Android est notée dans [backlog/ios.md](backlog/ios.md) ; rien n'est porté.

## Pièges rencontrés et leur solution

### Émulateur et Android

- **Version de publication qui s'arrête au lancement** (alpha-1 et alpha-2, 26-27 novembre 2026 : « kibuo s'arrête systématiquement ») : R8 compacte le code des versions de publication et avait retiré le constructeur de `WorkDatabase_Impl` que WorkManager crée par réflexion (`NoSuchMethodException … WorkDatabase_Impl.<init>` dans `adb logcat`). Règles dans `android/app/proguard-rules.pro`, icône des notifications gardée par `res/raw/keep.xml`. Les versions `--profile` ne sont pas compactées : toujours ouvrir la version `--release` sur l'émulateur `Kibuo_Release` avant un paquet ([releases/](releases/README.md)).

- **Émulateur saturé** (ANR, écran de démarrage figé, une capture qui prend une minute) : le redémarrer. `adb -s emulator-5554 emu kill`, puis `~/Library/Android/sdk/emulator/emulator -avd Pixel_10_Kibuo -no-snapshot-save &`, attendre `getprop sys.boot_completed` = 1. Deux utilisateurs Android actifs à la fois suffisent à le saturer : supprimer un utilisateur d'essai après usage (`pm remove-user <id>`). S'il bloque encore après un redémarrage : `emulator -avd Pixel_10_Kibuo -wipe-data` (accord du propriétaire du 25 novembre 2026, ses données sont perdues).
- **Après `install -r`, l'app rouvre l'écran où elle était** : prendre une capture avant de toucher, les coordonnées d'un écran ne valent pas pour un autre.
- **Utilisateur d'essai derrière l'écran de verrouillage** (capture noire, focus sur `NotificationShade`) : `adb shell input keyevent 224`, `wm dismiss-keyguard`, `input keyevent 82`, puis un glissement vers le haut.
- **Déposer un fichier chez l'utilisateur d'essai** : `adb push` vers `/storage/emulated/<id>/` est refusé. Pousser dans `/data/local/tmp/`, `chmod 644`, puis l'ouvrir dans kibuo : `adb shell am start --user <id> -a android.intent.action.VIEW -d file:///data/local/tmp/x.kibuo -t application/octet-stream -n app.kibuo/.MainActivity`.
- **Langue sur Android 13+** : la langue choisie est gardée par Android (`setAndroidAppLanguage`), pas dans la base ; d'où sa présence dans le résumé du fichier de sauvegarde.
- **Lancer la sauvegarde de fond à la main** : `adb shell cmd jobscheduler run -f -n androidx.work.systemjobscheduler app.kibuo <id>` (l'id se lit dans `dumpsys jobscheduler`, ligne `#AutoBackupWorker#`). Avant l'échéance, WorkManager la repousse (« executed before schedule ») ; éteindre puis rallumer l'interrupteur la relance aussitôt. `cmd time_detector suggest_manual_time` est refusé au shell : on ne peut pas avancer l'horloge par adb.
- **Internet, seulement pour la mesure d'usage** (ADR 0013, depuis le 25 novembre 2026) : l'autorisation `INTERNET` est dans le manifeste pour les messages que kibuo envoie lui-même à PostHog Europe (`lib/ui/usage/posthog_sender.dart`, sans module PostHog), après un « oui » seulement. La clé du projet (région EU, vérifiée le 25 novembre) est dans ce fichier (`postHogKey`). Tout nouvel événement passe par `lib/domain/usage/usage_event.dart`, dont les tests refusent un montant ou un texte saisi. Le module officiel de PostHog a été écarté : il ajoutait l'opérateur, le fuseau horaire et la signature technique du téléphone ; un nouveau module qui enverrait autre chose rendrait la politique fausse.
- **Coordonnées adb** : les captures sont réduites à 540 de large (×2 environ pour taper) ; avec deux appareils branchés, toujours `-s`.

### Base chiffrée (SQLite3 Multiple Ciphers)

- La clé est en hexadécimal brut : `PRAGMA hexkey = '…'` à l'ouverture.
- **Copier la base en clair** sans toucher au fichier : `VACUUM INTO 'copie'`, puis `ATTACH 'copie' AS c` (elle hérite de la clé) et `PRAGMA c.rekey = ''`.
- **Chiffrer une copie en clair** avec la clé du téléphone : l'ouvrir sans clé, `PRAGMA hexrekey = '<clé>'` (voir `replaceWithBackup` dans `lib/data/open_database.dart`).
- Une base d'un autre téléphone, ou dont la clé a disparu, s'ouvre en erreur « not a database » : c'est l'état `Unreadable`, le fichier est mis de côté, jamais effacé.
- **Migrations** : monter `KibuoDatabase.currentSchema`, `dart run build_runner build`, `dart run drift_dev make-migrations`, écrire le test contre les schémas sauvés (`test/drift/kibuo/`) et le voir échouer, puis ajouter l'étape `fromXToY`. Une base v11 venue d'une branche abandonnée (`codex/debts-receivables`) est réparée au démarrage (`_repairDebts`).

### Git

- **Commiter depuis un worktree** (`git worktree add`) : git passe au hook son propre `GIT_DIR`, que Flutter lit pour trouver sa version (« 0.0.0-unknown ») avant de refuser les paquets. Le hook `pre-commit` vide ces variables depuis le 26 novembre 2026.

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
- **Le verrou couvre tous les écrans** depuis le 25 novembre : `LockLayer` (dans le `builder` de `MaterialApp`, `lib/ui/lock/lock_gate.dart`) prend le relais de `LockGate` après sa première image. Avant, un écran ou une feuille ouverts par-dessus l'accueil restaient visibles après le reverrouillage, et le code des actions importantes n'y était pas demandé (`KibuoLock` n'était visible que depuis l'accueil). `KibuoLock` est maintenant visible partout ; `KibuoData` et `KibuoRestore`, eux, restent sur l'accueil seulement. Le navigateur de l'écran de déverrouillage est isolé (`HeroControllerScope.none`).
- Une feuille ouverte pendant que kibuo est verrouillé passe sous la couche du verrou depuis le 25 novembre ; on continue de ne rien ouvrir tant qu'il est verrouillé (voir `_openedFile` dans `lib/ui/shell/app_shell.dart`).
- Après un remplacement de la base, l'app se reconstruit grâce à une `KeyedSubtree` sur la base ouverte (`DataGate`).
