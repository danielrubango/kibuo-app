# L'Aperçu et la beta-1 (24 au 28 novembre 2026)

Bilan de la séance qui a livré la tuile agrandie, Catégories et la couleur des catégories, la sélection du montant au clavier, Patrimoine et la page d'un compte, puis construit le paquet `v0.1.0-beta-1`. Tout est fusionné dans `main` ; le paquet AAB est construit le 28 novembre.

## Ce qui a bien marché

- **Les variantes sur le canvas** : chaque choix ouvert (fond flouté ou voilé, points de pagination, flèches, couleurs, page d'un compte, jour sur la courbe) est passé par deux ou trois planches nommées, et le propriétaire a tranché en un mot (« P3 », « C1 », « B · avec courbe », « J3 »).
- **Les calculs d'abord testés** : le patrimoine dans le temps, l'écart d'une période, la projection, les entrées et sorties d'un compte (`lib/domain/overview/worth.dart`).
- **Le contrôle sur `Kibuo_Release`** : il a trouvé un vrai défaut avant le paquet (voir les leçons).

## Ses retours

- Le flou pour la tuile agrandie seulement ; partout ailleurs, le voile de la feuille du +.
- Les points de pagination seuls, sans phrase (P3) ; pas de flèches sur les lignes de Catégories (F3) ; des carrés pour la couleur (C1).
- Une dette ouverte ne dit ses montants qu'une fois ; au clavier, un montant proposé se remplace dès le premier chiffre, et se resélectionne d'un double toucher ou d'un appui long.
- La page d'un compte en variante B ; le jour marqué d'un trait et d'un point (J3), sur la page et sur l'onglet ; une › sur les comptes de la période.
- La note de la beta-1 reprend celle de l'alpha-3, pour les nouveaux testeurs.

## Composants ajoutés

Kit : `PageVeil`, `ShareBar`, `ColorGrid`, `SelectTaps`, `SelectedValue`, `KeypadText`. Aperçu : `ShareRow`, `PlainLineTile` (avec sa couleur), `LineSource` et `LinePage`, `WorthTab`, `WorthCurve` (points ancrés au jour, marque du jour), `AxisLabels` (date du jour en gris foncé), `AccountPage`. `OperationRow` peut dire son propre montant (un transfert signé sur la page d'un compte).

## Leçons

- **Une règle de solde vit à deux endroits.** Le solde d'un compte ignore ce qui est daté d'avant son ouverture (SQL, `_balanceChanges` dans `account_repository.dart`) ; Patrimoine refaisait le calcul en Dart sans cette règle. Aucun test ne comparait les deux : le défaut n'a été vu qu'au contrôle de la beta-1, parce que les données de `Kibuo_Release` contenaient ce cas.
- **Un test qui passe trop tôt ne prouve rien** : le premier test du défaut créait le compte après l'ouverture de l'écran, et passait sans la correction. Le voir échouer d'abord l'a montré.

## Améliorations de l'environnement, par gravité

1. **Une seule source pour « ce qui compte dans un compte ».** Exposer depuis `AccountRepository` les mouvements qui comptent pour le solde, et les faire lire par l'Aperçu ; puis un test d'invariant : pour chaque compte, l'ouverture plus ses mouvements égale son solde. Le défaut du 28 novembre aurait échoué à ce test.
2. **Les outils du canvas sont dans le dossier temporaire.** Les générateurs de planches (`cat_gen.py`, `acct_gen.py`, `jour_gen.py`, `tiles_*.py`) et la copie de travail du canvas vivent dans le scratchpad de la séance : un redémarrage les efface. Et [WORKING.md](../WORKING.md#le-canvas-de-design) pointe vers un canvas d'une autre organisation, injoignable ; celui qu'on utilise (`https://claude.ai/artifact/1W89dFz4aodFsKmmKeJj9R`) et sa façon de publier (`root` sur le dossier, `file_path` sur `project/canvas.json`) ne sont écrits nulle part. Ranger les générateurs dans `tool/boards/` et écrire le lien et la recette dans WORKING.
3. **L'émulateur se pilote à l'aveugle.** Sur la séance : 297 touchers par coordonnées calculées à partir de captures réduites, 409 captures, 691 images lues, et des attentes devinées d'après la taille de la capture (une fois, un écran blanc a été pris pour l'app chargée). Les textes de l'écran sont lisibles par `uiautomator dump` (vérifié : « Today », « See my accounts », chaque tuile). Un script `tool/emu.sh` avec `wait <texte>`, `tap <texte>` et `shot <nom>` (capture réduite à 900) remplacerait les calculs et la plupart des images.
4. **Chaque commit relance et imprime toute la suite.** Le crochet lance `tool/check.sh` (environ 40 s) à chacun des 384 commits, documentation comprise, et `flutter test` y écrit une ligne par test : 21 sorties trop longues pour être affichées. Mettre `flutter test --reporter failures-only` dans `check.sh`, et passer les tests quand le commit ne touche que `docs/`.
5. **Le nombre de tests dans STATE se périme.** Il a été faux deux fois (deux commits de correction). C'est une copie de ce que `flutter test` affiche : le retirer de STATE.
6. **Le contrôle d'une version de publication est fait à la main.** Construire, installer sur `Kibuo_Release`, ouvrir, chercher « FATAL EXCEPTION » : un script `tool/release_check.sh` le ferait d'un coup. Le premier lancement n'a pas été refait cette fois (il demande un utilisateur Android d'essai) : le script peut le créer, l'ouvrir et le supprimer.
7. **Deux pièges du shell.** zsh refuse `grep --include=*.dart` quand rien ne correspond dans le dossier (« no matches found ») : 41 emplois, plusieurs échecs ; écrire `--include='*.dart'`. Le `python3` de la machine n'a pas PIL : réduire ou recadrer une image avec `sips`. Une ligne dans le tableau « Environnement » de WORKING.
