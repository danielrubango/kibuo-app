# Rétro du 23 novembre : dettes, premier temps

Créer et lister les dettes et créances : la table des dettes (version 11 des données), le formulaire « Nouvelle dette ou créance », la liste par échéance ou par personne, la feuille d'affichage. Puis tes retours : le flou, fermer en touchant ailleurs, le + du bas.

## Ce qui a marché

- **Les tests d'abord** pour la migration, les règles de la liste (retard, mois, ordre, soldées) et l'enregistrement avec ou sans compte : rien de cassé sur les 500 tests déjà là.
- **Réutiliser le kit** : la saisie au pavé, le choix du compte, la feuille du taux et les choix d'affichage étaient déjà prêts.
- **Le parcours sur l'émulateur** a trouvé deux défauts avant toi (le clavier qui revenait après la date, l'heure 00:00 de l'opération), et une base laissée par une version d'essai (voir plus bas).

## Ce qui a moins bien marché

1. **Une base de l'émulateur déjà en version 11, sans dettes** : une version d'essai (branche « codex/debts-receivables », 19 novembre) avait pris le même numéro. La liste restait vide. Réparé par un ajout à l'ouverture, testé, qui ne supprime rien.
2. **J'ai suivi la planche à la lettre pour le flou et le +**, alors que l'app avait déjà une habitude (les boutons en pointillés de Comptes, Budgets, Récurrences) et que la direction prévoyait déjà de retirer le flou s'il gênait. Tu l'as vu, pas moi.
3. **Des taps mal placés pendant le parcours** quand l'émulateur ralentit (une page encore à l'écran reçoit le toucher suivant).

## Ce que je change

- **Avant de coder une planche, la comparer aux habitudes de l'app** (bouton de création, effets, titres de groupe) et te poser la question quand elles diffèrent, comme pour les espaces.
- **Un numéro de version des données n'est jamais partagé entre branches** : avant d'en prendre un, regarder les autres branches et ce qui a été installé sur les appareils.
- **Sur l'émulateur, relire l'écran avant chaque toucher** quand la machine est chargée.

## L'ouverture d'une ligne, en sept essais

Ce qu'on a essayé, dans l'ordre : le flou de la planche ; trois effets à comparer (pâle, sans effet, pâle et léger flou) puis un verre dépoli ; le léger flou avec un voile gris ; la ligne élargie jusqu'aux bords de sa carte ; un bloc intérieur à marges égales avec animation ; la carte posée au-dessus du voile sans pousser la page ; enfin les détails au-dessus ou en dessous, au choix.

Ce qu'on a appris :

- **Ce qui rapetisse ou bouge vient presque toujours de ce qui est derrière** : une carte parente qui change de hauteur, un cadre gris plus grand que la ligne, un flou qui s'étend en s'animant. Regarder le fond autant que la ligne.
- **Une ligne ouverte ne doit rien déplacer** : elle se pose au-dessus, seule active, et grandit en hauteur seulement.
- **Comparer sur ton téléphone, pas sur l'émulateur** : l'émulateur rend le flou en escalier et saccade les animations.
- **Une seule question à la fois** sur l'effet visuel ; et quand deux façons plaisent, les laisser au choix dans « Affichage ».

## Gardé

- Ouverture : derrière, la page pâlit, se floute légèrement d'un coup et passe sous un voile gris ; la carte de la ligne reste blanche au-dessus, ses autres lignes pâlissent ; la carte ne grandit qu'en hauteur.
- « Ouvrir une ligne » dans « Affichage » : détails au-dessus (au départ) ou en dessous.
- Un guide en deux étapes, montré une seule fois, la première fois que la liste a une ligne.
- La confirmation « Dette enregistrée » en feuille, comme une opération, avec ✕ et compte à rebours (partagé dans le kit).
- Le bloc intérieur, revenu : toujours à 8 des bords de la carte, son cadre (contour et ombre) apparaît en fondu ; rien ne glisse sur les côtés. En deux temps : le cadre puis les détails à l'ouverture, l'inverse à la fermeture.
- La fenêtre du guide épouse la carte, ses côtés et ses coins.
- Dans les feuilles d'affichage, une description trop longue défile lentement jusqu'à sa fin puis revient (composant du kit, partout).

Leçon de plus : **un cadre qui apparaît vaut mieux qu'un cadre qui s'élargit** ; et une fenêtre de mise en avant doit suivre exactement la forme qu'elle montre.

## Composants

- La ligne de date du formulaire de compte est devenue un composant du kit, réutilisé pour l'échéance.
- Le compte à rebours de la confirmation est un composant du kit, commun à l'opération et à la dette.
- La ligne qui défile (`ScrollingLine`) est un composant du kit, utilisé par tous les choix d'affichage.
- La ligne qui s'ouvre au-dessus d'un voile n'existe que dans la liste des dettes : elle rejoindra le kit le jour où un deuxième écran l'emploie (À traiter, Projets).

## Deuxième temps (fiche et remboursements)

- **Ce qui a marché** : le dessin d'abord pour l'allure des opérations de dette (A, puis A1 à A3, puis A4 retenue) ; les données écrites tests d'abord (rembourser, modifier, supprimer : 11 cas) ; la fiche et la feuille « Rembourser » suivies sur leurs planches.
- **Tes retours en route** : le solde dans le choix du compte, la ligne qui reste ouverte derrière la feuille et la fiche, le titre qui dit l'action (« Emprunt à Jean », « Remb. à Jean » si la place manque), et les vibrations.
- **Composants** : les vibrations sont dans le kit (touches du pavé, boutons, interrupteurs, choix, onglets, lignes de refus) : trois forces, réglées par le téléphone ; le choix du compte (avec solde) reste une seule feuille partagée.
- **Leçon** : une action qui part d'un endroit (une ligne ouverte) doit y ramener, à jour ; ne jamais refermer ce que la personne regardait.



1. **L'ouverture d'une ligne** : à valider sur ton téléphone.
2. **La suite** : le deuxième temps (fiche, « Rembourser », modifier, solder, supprimer) et le style « provisoire » des opérations de dette dans Opérations.
