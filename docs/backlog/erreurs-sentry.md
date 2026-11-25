---
title: Erreurs dans Sentry, si PostHog ne suffit plus
milestone: Après la 1.0
labels: [confidentialité, réseau]
---

# Erreurs dans Sentry, si PostHog ne suffit plus

La mesure d'usage et les erreurs partent vers PostHog dès la version 0.1, avec l'accord de l'utilisateur ([ADR 0013](../adr/0013-mesure-d-usage-anonyme.md), décidé le 25 novembre 2026).

Le propriétaire envisage de passer les erreurs à [Sentry](https://sentry.io) plus tard, ou de continuer avec PostHog. À revoir si les erreurs de PostHog manquent de détail (fils d'exécution, symboles natifs, regroupement). Les mêmes règles s'appliqueraient : même accord, aucun message d'erreur ni contenu saisi, aucune adresse IP, le numéro tiré au sort de l'ADR 0013.
