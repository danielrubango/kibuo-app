# Couleur des catégories

Décidé le 27 novembre 2026, pour l'onglet Catégories de l'Aperçu (version 0.2, livraison 4). Chaque catégorie a sa couleur, choisie dans une palette de dix (Pêche, Abricot, Sable, Corail, Rose, Lavande, Bleu, Ciel, Menthe, Vert) ; le gris est réservé à « Autres ». Une sous-catégorie n'a pas de couleur à elle : elle prend celle de sa catégorie.

La base garde **le nom de la couleur** (`peach`, `rose`…), dans une nouvelle colonne de la table des catégories, et non sa teinte. L'app traduit ce nom en teinte au moment de dessiner : le thème sombre (version 0.4) pourra donner à chaque couleur sa version sombre sans toucher aux données, et la palette pourra être ajustée sans migration.

Les catégories existantes reçoivent leur couleur par une migration de la base (version 15) : une couleur fixée pour chaque catégorie fournie par l'app (PRODUCT), la couleur la moins utilisée de sa liste (Dépenses ou Revenus) pour chacune de celles que l'utilisateur a créées, dans leur ordre, et le gris pour les « Autres », la régularisation, les dettes et les créances. Une catégorie créée ensuite suit la même règle de la moins utilisée.

Une sauvegarde est une copie de la base ([ADR 0012](0012-format-du-fichier-de-sauvegarde.md)) : la couleur y voyage sans changer le format, et une sauvegarde plus ancienne, restaurée, passe par la même migration.

## Considered Options

- Garder la teinte elle-même (un nombre de couleur) : plus simple à dessiner, mais le thème sombre aurait dû réécrire chaque catégorie, et une teinte choisie en clair peut être illisible en sombre.
- Une couleur par rang dans la liste (la 1re, la 2e…), sans rien garder : une catégorie aurait changé de couleur d'un mois à l'autre. Écartée par le propriétaire au profit d'une couleur propre.
- Une couleur pour les sous-catégories aussi : plus de choix à faire pour l'utilisateur, et des barres de couleurs différentes sous une même catégorie. Écartée.

## Consequences

La colonne est vide pour une sous-catégorie ; tout ce qui dessine une catégorie demande sa couleur à travers sa catégorie parente. Le gris ne se choisit pas : il reste aux catégories de l'app qui ne se modifient pas ou qui regroupent le reste.
