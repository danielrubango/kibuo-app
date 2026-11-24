# Planches du canvas « Kibuo - Identité et directions »

Export du 24 novembre 2026 : 259 planches `.dc.html` et le plan du canvas (`canvas.json` : pages, titres, positions).

## Les ouvrir

Ouvrir une planche dans Chrome ou Firefox depuis ce dossier. `support.js` est le moteur d'affichage du canvas (type « Design », basé sur React, licence MIT pour React) : il fait tourner les listes et valeurs calculées des planches. Avec Chrome en ligne de commande, les fichiers locaux demandent `--allow-file-access-from-files`.

## Pages et état

La page de chaque planche et son titre sont dans `canvas.json` (`boards.<fichier>.page` et `.title`). Les pages : Identité, Système de design, Revue de fidélité, Accueil et navigation, Premier lancement, Réglages, Dettes, projets et récurrences, Opérations, Aperçu, Budgets, Projets, En cours.

- Une planche sans page (`page` absent : 36 fichiers, par exemple `BarreIconesA`, `PinCreaA`, `SigneA`) est une variante écartée : à vérifier au cas par cas.
- Sur la page « En cours », les titres disent « retenue » ou « non retenue ».
- Le tableau détaillé (écran, état, code qui l'implémente) reste à écrire : voir docs/STATE.md, à venir.
