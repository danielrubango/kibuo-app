---
title: Sauvegarde cloud et synchronisation multi-appareil
milestone: Cloud
labels: [synchro, backend]
---

# Sauvegarde cloud et synchronisation multi-appareil

Pour les détenteurs d'un Compte Kibuo. Fonction non prioritaire et non mise en avant au départ. Fonctionnement semi-offline : l'application reste utilisable sans réseau, se synchronise au retour d'internet et demande à l'utilisateur de trancher les conflits.

Décisions déjà prises : [données prêtes](../adr/0003-donnees-pretes-pour-la-synchro.md), [Laravel et PostgreSQL](../adr/0007-synchro-laravel-postgresql.md), [chiffrement de bout en bout](../adr/0008-chiffrement-de-bout-en-bout.md), [conflits par champ](../adr/0009-conflits-par-champ.md).

Le serveur vivra dans [danielrubango/kibuo-api](https://github.com/danielrubango/kibuo-api), avec le [site public](site-public.md).

À décider : mode de connexion, écran de résolution des conflits, gestion des appareils, journal détaillé des changements, hébergement.

- Ce qui reste propre au téléphone ne se synchronise pas, même rangé dans la table des préférences : les astuces déjà vues (`hint_*`) et les recherches récentes (`search_recent`).
