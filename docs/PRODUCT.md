# Produit

Kibuo aide à savoir où part son argent et à préparer ce qui compte, sans dépendre d'internet ni d'un compte en ligne. Le vocabulaire est défini dans [GLOSSARY.md](../GLOSSARY.md).

## Cadre de la V1

- Android, version 8 au minimum. Appareil de référence : Poco M3 (6 Go de RAM), plus émulateurs.
- Français et anglais ; d'autres langues s'ajouteront progressivement.
- Totalement offline, sans compte obligatoire, sans IA, sans publicité.
- Gratuite. L'usage offline reste gratuit à vie ; les services en ligne pourront être payants.
- Usage individuel. Un partage en lecture seule viendra plus tard.

## Modules de la V1

### Comptes et opérations

- Plusieurs comptes (espèces, banque, mobile money, épargne) et transferts entre eux.
- Dépenses et revenus classés par catégorie. Catégories traduites et modifiables, un seul niveau de sous-catégories.

### Devises

- L'utilisateur ajoute ses devises, désigne la principale et saisit les taux de conversion, modifiables à tout moment.
- Chaque compte garde sa devise. La devise principale sert au suivi et de valeur proposée par défaut.
- Une opération dans une autre devise que celle de son compte est convertie vers la devise du compte. Le montant d'origine et le taux figé sont conservés.
- Une conversion passée ne change jamais.
- Les rapports peuvent convertir à une date choisie. Le total du patrimoine utilise les taux du jour.
- Changer de devise principale ne modifie que l'affichage et les rapports.

### Budgets

- Un budget par catégorie et par période, en devise principale. Les opérations en autre devise comptent selon leur taux figé.
- Le jour de début de période est réglable (par exemple le jour de paie).
- Pas de report du reste d'une période à l'autre.

### Récurrences

- Une récurrence crée directement l'opération par défaut. Un réglage global fixe ce comportement, et chaque récurrence peut le remplacer pour rester en brouillon.
- Si l'application n'a pas été ouverte le jour prévu, les occurrences manquées sont créées à leur date d'origine, avec une notification.
- Modifier une récurrence ne change que les occurrences futures.

### Dettes et créances

- Contrepartie sous forme de simple nom, sans accès aux contacts du téléphone.
- Date d'échéance et remboursements partiels.
- Chaque mouvement peut être lié à un compte. Ce lien reste optionnel pour une dette ancienne.
- Pas de calcul d'intérêts.

### Projets

- Chaque versement est un transfert vers un compte d'épargne, qui peut porter plusieurs projets.

### Rappels et alertes

Notifications locales uniquement :

- rappel général de saisie ;
- calendrier propre à chaque dette, créance et projet ;
- alertes de budget à 80 % et 100 % ;
- pour réclamer un remboursement, un message pré-rempli que l'utilisateur envoie lui-même par SMS ou WhatsApp.

Certaines marques Android retardent les notifications pour économiser la batterie : prévoir un guide de réglage et des tests sur ces appareils.

### Tableaux de bord

Graphiques simples. L'accueil affiche le total en devise principale, le reste de la période, les prochaines échéances, et les dettes et créances.

## Navigation et saisie

- Premier lancement : langue, devise principale, premier compte, puis PIN et sauvegardes proposés sans être imposés.
- Barre du bas : Accueil, Opérations, bouton **+** central qui dépasse vers le haut, Budgets, Projets.
- Réglages et « Plus » via une icône en haut de l'accueil.
- Dettes et créances : section de l'accueil, et accès depuis le +.
- Le + ouvre une feuille montante sur « Dépense », clavier numérique affiché, avec Revenu, Transfert, Dette et Épargne en un geste. Objectif : moins de 10 secondes pour une dépense.

## Protection des données

- Base de données chiffrée, verrouillage par PIN ou biométrie.
- PIN oublié : biométrie si active, sinon code de récupération, sinon effacement et restauration d'une sauvegarde.
- Sauvegardes automatiques **au choix de l'utilisateur** : hebdomadaires, dans un dossier choisi, avec un rappel si la dernière date trop.
- Fichier de sauvegarde versionné, chiffrement par mot de passe proposé mais optionnel.
- Restauration par remplacement complet, après une sauvegarde automatique de l'état actuel.
- Export CSV séparé.

## Après la V1

Voir [docs/backlog/](backlog/).
