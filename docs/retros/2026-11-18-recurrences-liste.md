# Rétro du 18 novembre : les récurrences dans la liste

Troisième des quatre livraisons des récurrences : brouillons, ignorés et opérations prévues dans la liste des opérations, fiche d'un brouillon, feuille « Affichage de la liste », ligne « Récurrences et brouillons » dans Plus, brouillons dans la recherche. 456 tests, parcours sur l'émulateur, pas encore validé ni commité.

## Ce qui a marché

- **Les planches relevées avant de coder** : la carte du brouillon, la ligne ignorée, la ligne prévue, la fiche et la feuille d'affichage reprennent leurs mesures (pointillés, teintes, tailles, textes).
- **Le kit a encore servi** : la ligne d'opération porte maintenant les variantes « Ignoré » et « Prévu » au lieu d'un nouveau composant ; la feuille d'affichage reprend les choix de celle des Budgets ; le court message en bas d'écran est devenu un composant du kit.
- **Les données d'abord, testées** : les opérations prévues et les réglages d'affichage ont eu leurs tests avant le code des écrans.
- **L'émulateur sans rien effacer** : pour voir les brouillons, j'ai créé une récurrence de démonstration, puis je l'ai arrêtée et j'ai supprimé l'opération qu'elle avait faite. Tes données sont revenues comme avant.

## Ce qui a moins bien marché

1. **Les espaces entre groupes, vus par toi (même famille d'écart, 4e fois).**
   - J'ai comparé les planches pour les cartes elles-mêmes, pas pour l'espace entre deux groupes ni entre un titre et ses éléments.
   - Le relevé fait après ton retour montre cinq façons de faire dans le code :
     - entre deux jours d'Opérations : environ 36 au-dessus de la date ;
     - entre deux types de Comptes : environ 29 ;
     - entre deux groupes de Budgets : 14 ;
     - entre deux groupes de Récurrences, de Recherche ou de Devises : 16.
   - Les planches disent 14 ou 16 entre deux groupes, et 6 ou 8 entre un titre et son contenu.
   - La règle « date posée en bas de sa ligne de 44 », prise le 18 pour rapprocher la date de ses cartes, a ajouté du blanc au-dessus de chaque jour : la ligne de 44 compte dans l'espace visible.
2. **Le titre « À valider · 2 » fait à la main.** J'ai relevé la planche BrouillonA3, pas celle de la liste (ListeOperations), qui l'écrit en noir avec « En retard et du jour » à droite. Le code n'a ni l'un ni l'autre, et n'utilise aucun titre du kit.
3. **Deux petits restes de la démonstration** : la récurrence arrêtée reste dans la base (invisible), et l'émulateur était éteint au départ, ce qui a coûté un démarrage.

## Ce que je change

- **Un seul composant de groupe** dans le kit (titre, compte « · 3 », valeur ou action à droite, repli éventuel), avec ses espaces fixés une fois, pour tous les écrans qui groupent : Opérations, détail d'un budget, Comptes, Budgets, Récurrences, Recherche, Devises, feuilles, puis l'accueil.
- **Relever les espaces entre groupes sur toutes les planches** qui groupent, avant de coder une liste, et poser la question s'ils diffèrent.
- **Lire toutes les planches où un élément apparaît**, pas seulement la plus récente.

## Décisions du 18 novembre

1. **20 entre deux groupes**, et autant entre un bloc et le premier groupe : 14, puis 16 et 20 essayés sur le téléphone ; à 14, les groupes ne se détachaient pas assez des 8 entre deux cartes. Une seule valeur du kit (`GroupTitle.gap`).
2. **8 partout ailleurs** : entre un titre et son premier élément, et entre deux éléments.
3. **Un titre qui se replie** est centré dans une zone de toucher de 32 (8 au-dessus et au-dessous du texte), sur toute la largeur, sans déborder.
4. **Deux formes d'éléments** : des cartes séparées (opérations, comptes, résultats) ou des lignes d'une même carte (budgets, récurrences, À traiter, réglages).
5. **Un seul style de titre**, gris ; « À valider · 2 » dit « En retard et du jour » à droite.
6. **Un seul composant de groupe** dans le kit, appliqué à tous les écrans qui groupent, dans un commit à part avant la fusion de la livraison 3.

Écrit dans `DIRECTION.md` (« Groupes »).
