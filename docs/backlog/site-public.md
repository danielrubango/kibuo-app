---
title: Site public de kibuo
milestone: Version 0.1
labels: [site, backend]
---

# Site public de kibuo

**Décidé le 26 novembre 2026** :

- **Pour commencer, la page de confidentialité seule**, en français (`kibuo.app/confidentialite`, l'adresse donnée à Google Play) et en anglais (`kibuo.app/en/privacy`). Le même texte que dans l'app, avec deux ajouts : qui publie kibuo (Daniel Rubango) et la durée de conservation des statistiques. La page d'accueil vient plus tard (ROADMAP).
- **Hébergement** : Cloudflare Pages, gratuit, là où le domaine `kibuo.app` est déjà géré, à partir du dépôt privé `kibuo-api`. Vercel reste une possibilité plus tard. À terme, le site rejoint l'API sur un serveur à nous (VPS), en Laravel avec Inertia.
- **Courrier** : `contact@kibuo.app` suivi vers la boîte habituelle du propriétaire par le routage d'e-mails de Cloudflare.
- **Design** : trois départs (A, B, C) sur un canvas, choisis avant tout code ; le passage en HTML se fait à la fin.

Vit dans le dépôt [danielrubango/kibuo-api](https://github.com/danielrubango/kibuo-api), avec le serveur de la [synchronisation](sync-cloud.md) qui viendra plus tard (Laravel, voir l'[ADR 0007](../adr/0007-synchro-laravel-postgresql.md)).

Pages attendues :

- présentation de kibuo et lien vers Google Play ;
- politique de confidentialité, demandée par Google Play dès la publication (phase 8) ;
- conditions d'utilisation ;
- demande de suppression de compte et de données, que Google Play exige d'une appli où l'on peut créer un compte : elle devra exister quand le Compte kibuo arrivera ;
- contact et aide.

Sans Compte kibuo, la V1 garde tout sur le téléphone : la politique de confidentialité le dit, et la suppression se fait en effaçant les données de l'appli.
