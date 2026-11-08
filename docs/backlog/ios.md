---
title: Portage sur iOS
milestone: iOS
labels: [plateforme]
---

# Portage sur iOS

Le code Flutter reste compilable pour iOS, mais iOS n'est ni testé ni publié avant la stabilisation d'Android.

## Registre des spécificités Android

À compléter dans le même changement que tout ajout dépendant d'Android.

| Fonction | Élément propre à Android | Équivalent iOS | État |
|---|---|---|---|
| | | | |

## Différences déjà connues

| Sujet | À prévoir sur iOS |
|---|---|
| Biométrie | Face ID et Touch ID, avec la mention d'usage requise |
| Stockage de la clé | Trousseau iOS, en excluant la synchronisation iCloud |
| Rappels | Limite du nombre de notifications programmées à vérifier |
| Sauvegardes | Sélecteur de fichiers et dossier iCloud ou local |
| Serveur web local | Fonctionne uniquement application ouverte, comme accepté |
| Modèle d'IA système | iPhone 15 Pro ou plus récent, si l'IA embarquée est retenue |

## Étapes

1. Relire le registre et vérifier chaque dépendance sur iOS.
2. Compiler et lancer sur le simulateur.
3. Adapter les permissions et la mise en page.
4. Tester sauvegarde, restauration et transfert depuis Android.
5. Tester sur un iPhone réel, puis publier via TestFlight et l'App Store.
