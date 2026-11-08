# Synchronisation sur Laravel et PostgreSQL, avec une API sur mesure

La future synchronisation multi-appareil repose sur un backend Laravel et PostgreSQL, avec une API d'envoi et de récupération des changements. L'environnement Laravel (Herd) est déjà en place sur la machine de développement, le coût serveur reste faible et l'écran de conflits doit nous appartenir entièrement.

## Considered Options

- PowerSync : brique prête, mais l'écriture passe quand même par notre backend, et sa capacité à porter notre résolution de conflits n'a pas été confirmée.
- Supabase : démarrage rapide, mais plus de dépendance à un fournisseur.
