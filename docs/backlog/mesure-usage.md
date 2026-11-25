---
title: Mesure d'usage, avec l'accord de l'utilisateur
milestone: À décider
labels: [confidentialité, réseau]
---

# Mesure d'usage, avec l'accord de l'utilisateur

Noté le 25 novembre 2026 à la demande du propriétaire : savoir ce que les utilisateurs font dans kibuo, pour l'améliorer, sans les déranger. Outil envisagé : [PostHog](https://posthog.com).

## Ce que cela change

- kibuo n'a aujourd'hui pas accès à Internet (STATE, pièges). La mesure d'usage serait la première raison de l'ajouter : l'autorisation `INTERNET` n'arrive qu'avec elle.
- La politique de confidentialité (À propos) dit « Rien ne part » et « pas de mesure d'audience » : elle devra changer dans la même livraison, et le site avec elle.
- Le formulaire « Sécurité des données » de Google Play devra déclarer ce qui est recueilli.

## Pistes à trancher le moment venu

- **Accord** : seulement si l'utilisateur accepte, désactivé par défaut, demandé une fois (au premier lancement ou plus tard), réglable dans Réglages › Confidentialité.
- **Ce qui part** : les écrans ouverts et les actions (« opération enregistrée », « budget créé »), la version de kibuo, le modèle et la version d'Android, la langue. Jamais un montant, un libellé, un nom de compte, une personne, une note ou une pièce jointe.
- **Identité** : un identifiant au hasard, propre à kibuo, sans lien avec le téléphone ni avec le compte Google ; il change si l'utilisateur retire son accord puis le redonne.
- **Hébergement** : PostHog en Europe (ou hébergé par kibuo), à comparer.
- **Sans réseau** : les événements attendent le réseau, sans gêner l'utilisation hors ligne.
- **Quand** : pendant le test fermé de la 0.1 il serait déjà utile, mais il ajoute le réseau et change la politique ; à placer avec le propriétaire.
