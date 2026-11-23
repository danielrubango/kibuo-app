# Rétro du 23 novembre : la phase Planification

De la liste des récurrences (18 novembre) aux alertes de budget (19 novembre) : brouillons et opérations prévues dans la liste, accueil (« À traiter », « À venir »), règle des groupes, retouches (feuille +, clavier, types de compte), haut des feuilles, rappels en trois livraisons, opération datée plus tard et sa fiche, alertes de budget. La phase 4 est terminée ; 511 tests.

## Ce qui a marché

- **Une série de questions avant chaque livraison**, validée d'un mot : aucune livraison n'a été refaite sur le fond. Les retours ont porté sur la forme (espaces, arrondi d'une ligne glissée, haut des feuilles).
- **Les composants du kit** ont tenu la cohérence : un seul titre de groupe pour dix écrans (et une seule valeur, 20, réglée en une ligne), le message en bas avec « Annuler », la ligne « Rappel » partagée entre récurrence et opération prévue.
- **Les tests ont trouvé de vrais défauts** avant toi : l'âge d'un taux compté un jour de trop juste après minuit (heure universelle), les catégories par défaut créées deux fois au démarrage (l'accueil et la liste en même temps), la liste des opérations pas rechargée après un changement fait depuis l'accueil.
- **L'émulateur avec des données de démonstration, puis remises comme avant**, et ton téléphone mis à jour par-dessus après chaque validation, sans rien effacer.
- **Essayer deux réglages côte à côte** (16 et 20 entre les groupes) a permis de choisir en voyant, plutôt qu'en lisant des chiffres.

## Ce qui a moins bien marché

1. **Deux décisions qui se contredisaient** (une seule notification par échéance, mais aussi une le jour même). Je l'ai vu au moment de coder, pas au moment de poser les questions.
2. **Un module trop récent** : la dernière version des notifications exigeait un Android plus récent que le projet ; une construction perdue avant de prendre la version précédente.
3. **Des modifications automatiques trop larges** : en remplaçant la poignée des feuilles, une recherche a touché deux ouvertures de pages. L'analyse l'a vu tout de suite, mais c'était évitable.
4. **Une fois, du travail commencé sur la version principale** au lieu d'une branche (haut des feuilles) ; rattrapé avant le commit.
5. **Les espaces des groupes en trois essais** (14, puis 16 et 20) : la première proposition ne regardait que la planche, pas l'effet à l'écran.
6. **Des aides de test copiées d'un fichier à l'autre** (attendre la base, comparer un montant avec ses espaces insécables) : une douzaine de copies.

## Ce que je change

- **Relire les questions entre elles avant de te les poser** : chaque réponse proposée doit tenir avec les autres et avec ce qui est déjà écrit dans `PRODUCT.md`.
- **Vérifier la compatibilité d'un module** (version d'Android exigée) avant de l'ajouter.
- **Créer la branche dans la même commande** que le premier changement, et vérifier la branche avant chaque commit.
- **Pour une mesure qui se voit (espace, taille), montrer deux essais** dès la première proposition.
- **Modifier par remplacements exacts**, jamais par recherche large, dans le code.

## Fait aujourd'hui

- **Composants** : l'en-tête des fiches d'une opération qui n'en est pas encore une (brouillon, ignorée, prévue), la note encadrée, la feuille de choix à coche, et un raccourci pour la graisse du texte remplacent leurs copies. Seul écart visible : « Dépense prévue » passe en graisse moyenne, comme sur la fiche d'un brouillon.

## À décider

1. **Les aides de test** : les réunir dans un fichier commun (proposé).
2. **Les rappels à l'heure exacte** : aujourd'hui, une notification peut arriver jusqu'à une heure en retard ; l'heure exacte demande une autorisation contrôlée par le Play Store.
3. **Valider un brouillon** depuis la liste ou « À traiter » ne déclenche pas encore l'alerte de budget.
4. **Modifier une opération prévue** depuis sa fiche (aujourd'hui : annuler puis saisir de nouveau).
