# Roadmap

Une case cochée signifie : réalisé et validé par le propriétaire. À la création du suivi sur GitHub, ce fichier sera porté selon [backlog/github.md](backlog/github.md).

**Prochaine étape : la première case vide de la version 0.1.**

## Le plan (décidé le 25 novembre 2026)

kibuo sort tôt sur Google Play, puis s'enrichit version par version :

- **0.1** : la première publication, avec ce qui est déjà construit et seulement ce qui manque pour ne pas paraître inachevé ou ce que Google Play exige.
- **0.2 à 0.5** : une nouveauté principale par version, publiée au fil de l'eau.
- **1.0** : la version stable et complète, après quelques semaines de test des versions 0.x par de vrais utilisateurs. C'est elle que les documents appellent « la V1 » ([PRODUCT.md](PRODUCT.md), « Cadre de la V1 »).
- **Après la 1.0** : les grands chantiers (cloud, IA, iOS…), dans cet ordre de départ, à revoir selon les retours.

Les phases 0 à 6 ci-dessous sont l'historique de la construction.

## Phase 0 : Fondations du projet

- [x] Cadrer le produit et les décisions
- [x] Choisir le nom
- [x] Créer le dépôt local et la documentation
- [x] Valider et commiter les fondations

## Phase 1 : Identité et design

Rien n'est codé avant la fin de cette phase.

- [ ] Vérifier les marques et réserver les domaines (déplacé en version 0.1)
- [x] Proposer quatre logos en SVG et en choisir un
- [x] Proposer trois directions visuelles sur l'accueil et la saisie rapide, et en choisir une
- [x] Maquetter le premier lancement
- [x] Maquetter l'accueil, avec dettes et créances
- [x] Maquetter la saisie rapide depuis le bouton +
- [x] Maquetter les opérations
- [x] Maquetter l'aperçu
- [x] Maquetter les budgets
- [x] Maquetter les projets
- [x] Maquetter les rappels et les réglages
- [x] Maquetter la sauvegarde et la restauration
- [x] Décliner le logo en icône Android

## Phase 2 : Socle technique

- [x] Installer Flutter, Android Studio et un émulateur
- [x] Vérifier une application vide sur l'émulateur (l'essai sur téléphone se fait en phase 7)
- [x] Mettre en place l'analyse et les tests automatiques
- [x] Créer le thème issu du design, avec l'icône de l'application
- [x] Créer la navigation avec le bouton + central
- [x] Recentrer le logo et créer l'écran de démarrage
- [x] Mettre en place le français et l'anglais
- [x] Créer la base chiffrée, ses migrations et les métadonnées de synchro
- [x] Maquetter puis mettre en place le verrouillage par PIN et biométrie, et la confidentialité
- [x] Mettre en place le code de récupération, qui rouvre aussi les données copiées par Android sur un nouveau téléphone (voir l'ADR 0010)

## Phase 3 : Cœur de l'application

- [x] Devises, devise principale et taux de conversion
- [x] Comptes
- [x] Catégories et sous-catégories
- [x] Dépenses et revenus
- [x] Pièces jointes des opérations (photo, galerie, rangement et sauvegardes)
- [x] Transferts entre comptes, y compris entre devises
- [x] Découvert des comptes
- [x] Régularisation du solde d'un compte
- [x] Confirmer et protéger les actions importantes
- [x] Saisie rapide, dont la bulle qui fait découvrir l'appui long sur le +
- [x] Liste des opérations
- [x] Recherche des opérations
- [x] Premier lancement guidé
- [x] Accueil : date, disponible et bilan du mois ; les autres sections arrivent avec leurs modules
- [x] Montants courts (« 1,2 M FC »), réglables : automatique, toujours ou jamais

## Phase 4 : Planification

- [x] Budgets et période réglable
- [x] Récurrences, brouillons et rattrapage
- [x] Retouches avant les rappels (décidées le 18 novembre 2026, voir PRODUCT « À reprendre ») : feuille + à la planche, « Enregistrer » au-dessus du clavier pour un type de compte, gestion des types de compte
- [x] Rappels, avec les opérations datées plus tard et l'alerte de solde insuffisant trois jours avant
- [x] Alertes de budget

## Phase 5 : Dettes, créances et projets

- [x] Dettes et créances, avec remboursements partiels
- [x] Message pré-rempli pour réclamer un remboursement
- [x] Projets et versements
- [x] Rappels des dettes, créances et projets

## Phase 6 : Données

- [x] Sauvegarde manuelle
- [x] Restauration par remplacement, dont « J'ai une sauvegarde » au premier écran du premier lancement
- [x] Sauvegardes automatiques optionnelles, dont leur interrupteur à l'étape 4 du premier lancement
- [ ] Export CSV (déplacé en version 0.3)

## Version 0.1 : première publication sur Google Play

Ce qui manque dans l'app :

- [x] La vraie page Plus (planche `Plus`), à la place de la liste provisoire
- [x] La page Réglages, avec le choix de la langue après le premier lancement (planches `Reglages`, `ReglageLangue`)
- [x] À propos : version, politique de confidentialité, contact (planche `APropos`)
- [x] Aperçu : l'écran d'attente reste, avec un texte qui annonce les graphiques
- [x] « Enregistrer » grisé : bouton actif et premier champ manquant en rouge (décidé le 24 novembre, planches à montrer)
- [x] Interrupteurs : toute la ligne réagit, partout
- [x] Mesure d'usage anonyme et erreurs, avec l'accord de l'utilisateur (PostHog, [ADR 0013](adr/0013-mesure-d-usage-anonyme.md)) : demande à l'étape 4 et sur une feuille pour qui a déjà kibuo, interrupteur dans Confidentialité, politique de confidentialité mise à jour

Ce que Google Play exige :

- [x] Vérifier les conditions actuelles de Google Play pour un nouveau compte personnel (test fermé obligatoire, nombre de testeurs, durée ; fait le 25 novembre 2026 : [backlog/google-play.md](backlog/google-play.md))
- [ ] Vérifier la marque « kibuo » et réserver le domaine ([BRAND.md](BRAND.md))
- [x] Clé de signature de publication (créée par le propriétaire le 25 novembre 2026, hors du dépôt) et paquet AAB
- [x] Site public minimal : la politique de confidentialité, en ligne le 26 novembre 2026 à kibuo.app/fr/confidentialite/ et /en/privacy/ ([backlog/site-public.md](backlog/site-public.md))
- [ ] Fiche Google Play : textes, captures, formulaire sur la sécurité des données, classification du contenu ([backlog/fiche-google-play.md](backlog/fiche-google-play.md))
- [ ] Avant la production (vers fin décembre 2026) : des captures qui accompagnent l'utilisateur (flèches, parties d'écran mises en avant, chiffres), trois propositions de huit captures
- [ ] Parcours complets sur le Poco X3 NFC et un émulateur Android 8, dont ce qui n'est vu que par les tests (STATE)
- [ ] Test fermé sur Google Play (environ 12 testeurs, durée à confirmer), puis corrections
- [ ] Publication

## Version 0.2 : Aperçu

- [ ] Tableaux de bord : évolution, catégories, patrimoine, points suivis (planches `Apercu…`)

## Version 0.3 : Vos données, ailleurs

- [ ] Export CSV (planche `ExportCSV`)
- [ ] Envoyer une sauvegarde ailleurs (Drive, WhatsApp, e-mail) ([backlog/partage-sauvegarde.md](backlog/partage-sauvegarde.md))

## Version 0.4 : Thème sombre

- [ ] Toutes les maquettes en sombre, puis le choix clair, sombre ou réglage du téléphone ([backlog/theme-sombre.md](backlog/theme-sombre.md))

## Version 0.5 : Accompagner

- [ ] Premier lancement qui accompagne la première configuration ([backlog/premier-lancement.md](backlog/premier-lancement.md))
- [ ] Aide et support ([backlog/aide.md](backlog/aide.md)), « Noter kibuo »
- [ ] Guide de réglage des notifications selon les marques
- [ ] Ordre des catégories et sous-catégories ([backlog/ordre-categories.md](backlog/ordre-categories.md))

## Plus tard, avant la 1.0

- [ ] Feuille de route en ligne sur le site, partagée avec les testeurs ; plus tard, avec le site en Laravel, voter, demander et commenter les fonctions ([backlog/roadmap-en-ligne.md](backlog/roadmap-en-ligne.md), 26 novembre 2026)
- [ ] Page d'accueil du site kibuo.app : revoir la présentation de kibuo et le lien vers Google Play (décidé le 26 novembre 2026 : la 0.1 n'a que la page de confidentialité)

## Version 1.0 : stable

- [ ] Quelques semaines de test des versions 0.x par de vrais utilisateurs
- [ ] Corrections issues de ces tests
- [ ] Publication de la 1.0

## Après la 1.0

Dans cet ordre de départ (décidé le 25 novembre 2026), à revoir selon les retours :

1. **Compte kibuo et cloud** : sauvegarde en ligne, synchronisation entre appareils, chiffrement de bout en bout ([backlog/sync-cloud.md](backlog/sync-cloud.md)), offre payante ([backlog/offre-payante.md](backlog/offre-payante.md)), demande de suppression de compte sur le site public. Puis les **tontines** : une personne centralise, invite les autres et tient le compte à jour ; les autres reçoivent les mises à jour ([backlog/tontines.md](backlog/tontines.md), 26 novembre 2026).
2. **IA** : brouillons à partir d'un reçu, d'un SMS partagé ou d'un relevé ; questions naturelles ([backlog/ia.md](backlog/ia.md)).
3. **iOS** ([backlog/ios.md](backlog/ios.md)).
4. Ensuite : nouvelles langues ([backlog/langues.md](backlog/langues.md)), accès web local ([backlog/web-local.md](backlog/web-local.md)), coffre des cartes virtuelles ([backlog/cartes-virtuelles.md](backlog/cartes-virtuelles.md)), aller plus loin pays par pays ([backlog/aller-plus-loin.md](backlog/aller-plus-loin.md)), fonctionner en arrière-plan (rattrapage des récurrences et notifications sans ouvrir kibuo), couleurs des comptes.

Sujets détaillés dans [backlog/](backlog/).
