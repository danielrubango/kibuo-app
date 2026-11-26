---
title: Site public de kibuo
milestone: Version 0.1
labels: [site, backend]
---

# Site public de kibuo

**Décidé le 26 novembre 2026** :

- **Pour commencer, la page de confidentialité seule**, en français (`kibuo.app/fr/confidentialite/`, l'adresse donnée à Google Play) et en anglais (`kibuo.app/en/privacy`). Le même texte que dans l'app, avec deux ajouts : qui publie kibuo (Daniel Rubango) et la durée de conservation des statistiques. La page d'accueil vient plus tard (ROADMAP).
- **Hébergement** : Cloudflare Pages, gratuit, là où le domaine `kibuo.app` est déjà géré, à partir du dépôt privé `kibuo-api`. Vercel reste une possibilité plus tard. À terme, le site rejoint l'API sur un serveur à nous (VPS), en Laravel avec Inertia.
- **Courrier** : `contact@kibuo.app` suivi vers la boîte habituelle du propriétaire par le routage d'e-mails de Cloudflare.
- **Design** : trois départs (A, B, C) sur un canvas, choisis avant tout code ; le passage en HTML se fait à la fin.
- **Retenu le même jour** : la variante C1 (bandeau nuit, sommaire, date en petit sous le paragraphe), planche [SiteConfidentialite](../design/boards/SiteConfidentialite.dc.html), canvas « kibuo · Page de confidentialité », nettoyé pour ne garder qu'elle.
- **Statistiques dans la politique** : l'outil de mesure n'est pas nommé ; le texte dit que kibuo envoie des données d'analyse qui permettent d'améliorer l'application, stockées en Europe le temps de leur analyse, un an environ (l'offre gratuite de PostHog garde un an, ADR 0013). La phrase sur l'opérateur et le fuseau horaire, que kibuo n'envoie pas, est retirée. Le texte dans l'app suivra le même.
- **Un texte qui vaut pour chaque système** (même jour) : la politique parle de « l'appareil » et de « son système », sans nommer Android dans le texte courant, puisque iOS, une version hors ligne dans le navigateur et une version connectée viendront. Ce qui dépend du système (la copie par le système, effacer ses données) a une liste « Sur Android : … », à laquelle s'ajoutera une ligne pour chaque nouveau système quand il arrive.

**Construit le 26 novembre 2026** dans le dépôt `kibuo-api`, dossier `site/` (branche `feat/privacy-page`) : `confidentialite/index.html` (français), `en/privacy/index.html` (anglais), `index.html` qui renvoie vers la page française, `favicon.svg`, et les polices de l'app dans `site/fonts/` avec leurs licences, servies par le site lui-même (aucune police chargée chez Google, pour ne pas donner l'adresse des visiteurs). Le sommaire suit la lecture. Pages vérifiées le même jour dans un navigateur, à 375 px et en largeur d'ordinateur. Mise en ligne sur Cloudflare Pages : sans commande de construction, dossier publié `site`.

**En ligne le 26 novembre 2026** sur Cloudflare Pages, à kibuo.app. Le même jour, décidé par le propriétaire :

- **Chaque page sous sa langue** : `kibuo.app/fr/…` et `kibuo.app/en/…`, puisque le site sera multilingue. La politique est à `/fr/confidentialite/` et `/en/privacy/` ; l'ancienne adresse `/confidentialite/` mène à la page française pour de bon (fichier `site/_redirects`), et `/`, `/fr/`, `/en/` mènent à la politique de leur langue en attendant la page d'accueil.
- **Un sommaire qui suit la lecture** (variante A, planches `SiteSommaire-ordinateur` et `SiteSommaire-telephone`) : sur ordinateur, il reste visible pendant qu'on lit ; sur téléphone, c'est une barre en haut qui dit où l'on est et s'ouvre d'un toucher. La section lue est mise en valeur (fond menthe pâle dans le texte, ligne surlignée dans le sommaire) ; toucher une section, son titre ou une ligne du sommaire la met en valeur aussi.

**Visites du site** (26 novembre 2026) : Cloudflare ajoute de lui-même son outil de mesure des visites (Web Analytics, sans cookie) aux pages ; le propriétaire le garde. La politique du site a donc une section de plus, « Ce site » / « This site », placée avant « Qui publie kibuo » : nous comptons les visites pour les analyser et améliorer le site (dit comme une action de notre part, sans nommer l'hébergeur, à la demande du propriétaire), sans cookie et sans suivre le visiteur d'un site à l'autre (page lue, page d'origine, type de navigateur et d'appareil, pays). Cette section n'existe que sur le site : la politique de l'appli ne parle que de l'appli.

Vit dans le dépôt [danielrubango/kibuo-api](https://github.com/danielrubango/kibuo-api), avec le serveur de la [synchronisation](sync-cloud.md) qui viendra plus tard (Laravel, voir l'[ADR 0007](../adr/0007-synchro-laravel-postgresql.md)).

Pages attendues :

- présentation de kibuo et lien vers Google Play ;
- politique de confidentialité, demandée par Google Play dès la publication (phase 8) ;
- conditions d'utilisation ;
- demande de suppression de compte et de données, que Google Play exige d'une appli où l'on peut créer un compte : elle devra exister quand le Compte kibuo arrivera ;
- contact et aide.

Sans Compte kibuo, la V1 garde tout sur le téléphone : la politique de confidentialité le dit, et la suppression se fait en effaçant les données de l'appli.
