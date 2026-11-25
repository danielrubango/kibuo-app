# Mesure d'usage anonyme, avec l'accord de l'utilisateur

Décidé le 25 novembre 2026, pour la version 0.1. kibuo envoie des statistiques d'utilisation et ses erreurs à PostHog, seulement si l'utilisateur l'accepte. C'est la première fois que kibuo a accès à Internet. Le but est de suivre ce qui se passe pendant les versions 0.x et après, sans jamais pouvoir reconnaître un utilisateur.

- **Accord d'abord.** Rien ne part avant un « oui » explicite. La question est posée une fois : au premier lancement (étape 4), ou par une feuille à la prochaine ouverture pour qui a déjà kibuo. Réglages › Confidentialité garde un interrupteur pour changer d'avis.
- **Ce qui part.** Les écrans ouverts et les actions, sans leur contenu (« opération enregistrée, dépense », « budget créé », « sauvegarde faite ou échouée », « verrou activé »), la version de kibuo, la version d'Android, le modèle du téléphone, la langue, le pays du téléphone et le code de la devise principale. Jamais un montant, un libellé, un nom de compte ou de personne, une note, une pièce jointe, ni l'adresse IP.
- **Un numéro tiré au sort.** Les messages portent un identifiant tiré au hasard sur le téléphone (celui de l'outil de PostHog, jamais remplacé par un identifiant de la personne), gardé sur le téléphone, sans lien avec le téléphone, le compte Google ou la personne. PostHog ne crée pas de fiche par personne (`personProfiles: never`). Retirer l'accord efface le numéro ; un nouvel accord en tire un autre, sans lien avec le précédent.
- **Hébergement.** PostHog Cloud en Europe (`https://eu.i.posthog.com`), avec l'adresse IP jetée par le réglage du projet. Le compte et le projet sont au propriétaire ; la clé du projet est publique et rangée dans l'app.
- **Erreurs.** Les plantages partent par le même outil et le même accord : le type de l'erreur et l'endroit du code, sans le message, qui pourrait contenir un montant ou un nom.
- **Hors ligne.** Les messages attendent sur le téléphone et partent quand le réseau revient, dans une file limitée ; kibuo reste entièrement utilisable sans réseau.

## Considered Options

- Mesurer d'office avec possibilité de refuser : plus de données, mais contraire à la promesse de la politique de confidentialité et plus fragile vis-à-vis de Google Play et des utilisateurs européens.
- Aucune étiquette sur les messages : on compterait les écrans ouverts, pas les utilisateurs ni les parcours.
- Identifier la personne (compte Google, e-mail, identifiant du téléphone) : écarté, chaque utilisateur serait traçable.
- Sentry pour les erreurs : un second outil, un second texte dans la politique. Gardé pour plus tard si PostHog ne suffit pas ([backlog/erreurs-sentry.md](../backlog/erreurs-sentry.md)).
- Héberger PostHog soi-même : plus de maîtrise, mais un serveur à tenir avant même la publication.

## Consequences

L'autorisation `INTERNET` entre dans le manifeste ; la politique de confidentialité change dans la même livraison (« Rien ne part » devient ce qui part, avec accord), et le formulaire « Sécurité des données » de Google Play déclare l'activité dans l'app, les identifiants et les journaux de plantage, facultatifs. Chaque événement nouveau doit respecter la liste de ce qui part : un test vérifie qu'aucun montant ni texte saisi n'entre dans un événement. Moins d'utilisateurs accepteront qu'avec une mesure d'office : les chiffres seront un échantillon.
