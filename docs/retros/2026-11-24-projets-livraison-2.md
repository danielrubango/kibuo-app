# Projets, deuxième temps : la fiche et l'argent (24 novembre 2026)

## Ce qui a marché

- Les décisions d'abord (huit questions), écrites dans PRODUCT avant le code ; ta précision sur le transfert depuis un autre compte est arrivée à temps.
- Les cinq écrans manquants dessinés et validés avant de coder (sans date, refus, reprendre, terminé, supprimer).
- Les données et le plan écrits tests d'abord : le plan de la maquette (22 $ six fois, puis 18 $) est devenu un test ; le passage au schéma 14 aussi.
- Trois pièces des dettes sont passées dans le kit (barre hachurée, feuille de montant, ligne « libellé … valeur › ») et servent aux deux.

## Tes retours

- Des cases du plan qui dépassaient la carte, « Sur compte » au centre, des boutons texte placés et espacés chacun à sa façon, la ligne « Objectif atteint » trop haute et sans flèche, un message de succès qui couvrait le bouton du bas.
- Une note en double : l'effort par semaine était dans la carte du haut et dans le plan ; elle ne reste que dans le plan.
- La légende du repère montrée alors qu'aucune carte n'avait de repère.
- Un lien à droite de chaque carte de projet, « Détails » quand on ne peut plus mettre de côté.

## Composants

- `ActionUnderCard` : le bouton texte sous une carte, une seule règle de place et de marges (fiche projet, formulaire, dette).
- `CardLink` : le lien en fin de carte.
- La confirmation des mouvements d'argent réutilise la feuille des dettes, avec « Annuler ».

## Leçons

- **Vérifier à la largeur réelle, avec de vrais montants** : en francs, « 737 500 FC » ne tient pas dans une case pensée pour « 22 $ ». Je teste maintenant les écrans d'argent avec des montants longs.
- **Un élément qui glisse reste dans sa carte** : un défilement horizontal s'arrête au bord intérieur, jamais au-delà.
- **Une information, une place** : avant d'ajouter une phrase d'aide, chercher si l'écran la dit déjà.
- **Un message flottant ne va pas sur une fiche qui a un bouton en bas** : il le cache ; la feuille de confirmation le remplace.
