# Roadmap

Avancement de la V1, phase par phase. Une case cochée signifie : réalisé et validé par le propriétaire. À la création du dépôt GitHub, ce fichier sera porté selon [backlog/github.md](backlog/github.md).

**Prochaine étape : la première case vide.**

## Phase 0 : Fondations du projet

- [x] Cadrer le produit et les décisions
- [x] Choisir le nom
- [x] Créer le dépôt local et la documentation
- [x] Valider et commiter les fondations

## Phase 1 : Identité et design

Rien n'est codé avant la fin de cette phase.

- [ ] Vérifier les marques et réserver les domaines (voir [BRAND.md](BRAND.md))
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
- [ ] Rappels, avec les opérations datées plus tard et l'alerte de solde insuffisant trois jours avant
- [ ] Alertes de budget

## Phase 5 : Dettes, créances et projets

- [ ] Dettes et créances, avec remboursements partiels
- [ ] Message pré-rempli pour réclamer un remboursement
- [ ] Projets et versements
- [ ] Rappels des dettes, créances et projets

## Phase 6 : Données

- [ ] Sauvegarde manuelle
- [ ] Restauration par remplacement, dont « J'ai une sauvegarde » au premier écran du premier lancement
- [ ] Sauvegardes automatiques optionnelles, dont leur interrupteur à l'étape 4 du premier lancement
- [ ] Export CSV

## Phase 7 : Stabilisation

- [ ] Tableaux de bord
- [ ] Parcours complets sur le Poco X3 NFC et les émulateurs, dont un Android 8
- [ ] Guide de réglage des notifications selon les marques
- [ ] APK partagé à 5 à 10 testeurs
- [ ] Corrections issues des tests

## Phase 8 : Publication

- [ ] Vérifier les conditions actuelles de Google Play pour les nouveaux comptes
- [ ] Préparer la fiche, la politique de confidentialité et les captures (pages publiées sur le [site public](backlog/site-public.md))
- [ ] Publier sur Google Play

## Après la V1

- [ ] Couleurs des comptes, au choix dans une petite palette (carte du compte, filtres)

Sujets détaillés dans [backlog/](backlog/), à ordonner après la publication.
