# Mesure d'usage anonyme, avec l'accord de l'utilisateur

Décidé le 25 novembre 2026, pour la version 0.1. kibuo envoie des statistiques d'utilisation et ses erreurs à PostHog, seulement si l'utilisateur l'accepte. C'est la première fois que kibuo a accès à Internet. Le but est de suivre ce qui se passe pendant les versions 0.x et après, sans jamais pouvoir reconnaître un utilisateur.

- **Accord d'abord.** Rien ne part avant un « oui » explicite. La question est posée une fois : au premier lancement (étape 4), ou par une feuille à la prochaine ouverture pour qui a déjà kibuo. Réglages › Confidentialité garde un interrupteur pour changer d'avis.
- **Ce qui part.** Les écrans ouverts et les actions, sans leur contenu (« opération enregistrée, dépense », « budget créé », « sauvegarde faite ou échouée », « verrou activé »), la version de kibuo, la version d'Android, le modèle du téléphone, la langue, le pays du téléphone et le code de la devise principale. Jamais un montant, un libellé, un nom de compte ou de personne, une note, une pièce jointe, ni l'adresse IP.
- **Un numéro tiré au sort.** Les messages portent un identifiant tiré au hasard par kibuo (UUID v4), gardé dans le coffre du téléphone, sans lien avec le téléphone, le compte Google ou la personne. PostHog ne crée pas de fiche par personne (`$process_person_profile: false`). Retirer l'accord efface le numéro ; un nouvel accord en tire un autre, sans lien avec le précédent.
- **Hébergement.** PostHog Cloud en Europe (`https://eu.i.posthog.com`), avec l'adresse IP jetée par le réglage du projet. Le compte et le projet sont au propriétaire ; la clé du projet est publique et rangée dans l'app.
- **Erreurs.** Les plantages partent par le même outil et le même accord : le type de l'erreur et l'endroit du code, sans le message, qui pourrait contenir un montant ou un nom.
- **Hors ligne.** Les messages attendent sur le téléphone, dans un fichier, et partent par lots (toutes les 30 secondes, à 20 en attente, et quand kibuo passe en arrière-plan) ; au plus 500 attendent, les plus anciens partent d'abord ; kibuo reste entièrement utilisable sans réseau.
- **Notre propre envoi** (décidé le 25 novembre 2026, après essai). Le module de PostHog pour Flutter ajoutait de lui-même, depuis sa partie Android, le nom de l'opérateur, le fuseau horaire, la signature technique du téléphone (« user agent ») et son nom de code, sans moyen de les retirer depuis kibuo ; il interrogeait aussi son serveur au démarrage. kibuo n'embarque donc pas ce module : il envoie lui-même ses messages à l'adresse `/batch/` de PostHog, avec exactement les champs listés (`lib/domain/usage/usage_message.dart`, `lib/ui/usage/posthog_sender.dart`). La politique de confidentialité mentionne quand même l'opérateur, le fuseau horaire et la description technique comme possibles, pour pouvoir changer d'outil sans la réécrire.

## Le pays envoyé (26 novembre 2026)

Le pays des messages est la région choisie dans les réglages du téléphone (`usageCountry`, `lib/ui/device_country.dart`), et non plus celui du réseau ou de la carte SIM : ce dernier dirait où se trouve le téléphone, ce que Google Play compte comme une position approximative à déclarer. Le pays du réseau ne sert plus qu'à proposer une devise au premier lancement, sur le téléphone. Un test le vérifie (`test/usage_country_test.dart`).

## Vérifié chez PostHog le 26 novembre 2026

Pages officielles de PostHog, lues ce jour-là :

- **Durée de conservation** ([events-retention](https://posthog.com/docs/data/events-retention)) : un an sur l'offre gratuite, non réglable ; réglable seulement sur les offres payantes (2 ans par défaut). L'effacement se fait par mois entiers, et les copies de secours de PostHog gardent les événements environ deux semaines de plus ([data-storage](https://posthog.com/docs/privacy/data-storage)) : en pratique, jusqu'à environ 14 mois sur l'offre gratuite.
- **Adresse IP** ([data-collection](https://posthog.com/docs/privacy/data-collection)) : le réglage du projet « Discard client IP data » (Settings › Project) retire l'adresse avant de garder l'événement ; PostHog la reçoit quand même à chaque envoi. Il est éteint d'office pour les organisations européennes créées récemment : à vérifier dans notre projet. Rien ne dit si PostHog garde l'adresse dans les journaux de ses serveurs.
- **Contrat de sous-traitance** ([dpa](https://posthog.com/dpa)) : PostHog est sous-traitant, nous sommes responsables du traitement. Le contrat n'est pas automatique : il se génère dans PostHog (app.posthog.com/legal) et se signe, y compris sur l'offre gratuite.

## Considered Options

- Mesurer d'office avec possibilité de refuser : plus de données, mais contraire à la promesse de la politique de confidentialité et plus fragile vis-à-vis de Google Play et des utilisateurs européens.
- Aucune étiquette sur les messages : on compterait les écrans ouverts, pas les utilisateurs ni les parcours.
- Identifier la personne (compte Google, e-mail, identifiant du téléphone) : écarté, chaque utilisateur serait traçable.
- Sentry pour les erreurs : un second outil, un second texte dans la politique. Gardé pour plus tard si PostHog ne suffit pas ([backlog/erreurs-sentry.md](../backlog/erreurs-sentry.md)).
- Héberger PostHog soi-même : plus de maîtrise, mais un serveur à tenir avant même la publication.
- Le module officiel de PostHog pour Flutter (essayé le 25 novembre 2026) : moins de code à tenir, mais il envoie des champs hors de la liste et contacte son serveur au démarrage.

## Consequences

L'autorisation `INTERNET` entre dans le manifeste ; la politique de confidentialité change dans la même livraison (« Rien ne part » devient ce qui part, avec accord), et le formulaire « Sécurité des données » de Google Play déclare l'activité dans l'app, les identifiants et les journaux de plantage, facultatifs. Chaque événement nouveau doit respecter la liste de ce qui part : un test vérifie qu'aucun montant ni texte saisi n'entre dans un événement. Moins d'utilisateurs accepteront qu'avec une mesure d'office : les chiffres seront un échantillon.
