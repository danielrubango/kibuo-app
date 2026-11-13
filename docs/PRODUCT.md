# Produit

Kibuo aide à savoir où part son argent et à préparer ce qui compte, sans dépendre d'internet ni d'un compte en ligne. Le vocabulaire est défini dans [GLOSSARY.md](../GLOSSARY.md).

## Cadre de la V1

- Android, version 8 au minimum. Appareil de référence : Poco X3 NFC sous Android 15, plus émulateurs, dont un Android 8 pour le minimum.
- Français et anglais ; d'autres langues s'ajouteront progressivement.
- Thème clair uniquement ; le thème sombre viendra plus tard.
- Totalement offline, sans compte obligatoire, sans IA, sans publicité.
- Gratuite. L'usage offline reste gratuit à vie ; les services en ligne pourront être payants.
- Usage individuel. Un partage en lecture seule viendra plus tard.

## Modules de la V1

### Verrouillage

- Le PIN compte de 4 à 6 chiffres ; la longueur se choisit à sa création. Le déverrouillage montre autant de points et s'ouvre dès le dernier chiffre.
- L'empreinte est proposée juste après la création du PIN ; activée, elle est demandée en premier à chaque ouverture, avec « Utiliser le PIN » dessous.
- L'application se reverrouille après une absence réglable : immédiatement, 1 minute (par défaut) ou 5 minutes.
- Après 5 PIN faux, une attente s'impose (30 secondes), puis s'allonge à chaque nouvel échec (1 minute, 5 minutes…). Rien n'est jamais effacé automatiquement.
- Le code de récupération est remis à la création du PIN : 16 caractères en 4 groupes, affichés avec « Copier ». On retape un groupe pour prouver qu'on l'a noté. Un nouveau code s'obtient dans Réglages en donnant son PIN ; l'ancien cesse alors de fonctionner.
- Réglages › Sécurité tient en trois lignes : Verrouillage (PIN, empreinte, délai, clavier mélangé), Confidentialité, Code de récupération.
- Confidentialité : masquer Kibuo dans les applications récentes (activé par défaut) et autoriser les captures d'écran (activé par défaut), réglables séparément. Sous Android 8 à 12, qui ne sait pas les séparer, un écran au logo recouvre les soldes au passage en arrière-plan.
- Le clavier du code mélange ses chiffres à chaque ouverture et après chaque essai, pour qu'un regard par-dessus l'épaule ne permette pas de deviner le code. L'option peut être désactivée dans Réglages.

### Comptes et opérations

- Plusieurs comptes et transferts entre eux.
- Chaque compte a un type. Quatre types sont proposés d'emblée (espèces, banque, mobile money, épargne), et l'utilisateur peut créer les siens en leur attribuant une icône.
- Dépenses et revenus classés par catégorie. Catégories traduites et modifiables, un seul niveau de sous-catégories.
- Une opération peut être classée dans une catégorie principale ou dans une de ses sous-catégories, au choix. Une catégorie sans sous-catégorie se choisit directement.
- Une opération peut porter une note longue (affichée sur 3 lignes, dépliable) et jusqu'à 5 pièces jointes, par exemple la photo d'un reçu. Les pièces jointes s'affichent avec un aperçu ; on peut en cocher une ou plusieurs pour les retirer, ou en voir et remplacer une seule.
- La recherche porte sur tous les mois : libellé, catégorie, compte, note et montant, sans tenir compte des accents ni des majuscules. Elle propose les recherches récentes et des raccourcis (catégories, comptes, montant). Les résultats du mois affiché viennent d'abord ; ceux des autres mois sont repliés, et s'ouvrent seuls si le mois affiché n'a rien. Pas de total sur les résultats.
- Une opération peut être dupliquée : la saisie s'ouvre préremplie, à la date du jour.
- Après l'enregistrement, l'écran Opérations s'ouvre avec la nouvelle opération mise en avant, et une feuille récapitulative propose « Annuler et modifier » ou une nouvelle saisie du même type. Elle se ferme seule après quelques secondes, sauf si l'on touche son contenu ; un toucher à côté la ferme alors.
- Une opération peut porter des frais (changeur, retrait, envoi, transfert), saisis à la main et toujours dans la devise du compte. Ils restent visibles séparément dans le détail. Pour une dépense, ils s'ajoutent à ce qui sort du compte ; pour un revenu, ils sont déduits de ce qui arrive sur le compte ; pour un transfert, ils sont dans la devise du compte de départ et s'ajoutent à ce qui en sort.
- La saisie d'un transfert indique le compte de départ et le compte d'arrivée, sans catégorie. La devise suit le compte de départ ; si le compte d'arrivée est dans une autre devise, un taux s'applique et le montant arrivé est conservé.
- Le décompte d'une opération en autre devise se lit de haut en bas : montant payé, taux pour 1 unité de la devise du compte, montant converti, frais, puis le total retiré du compte. Il est replié sur ce total dans la saisie ; toucher le total le déroule ou le replie. Le taux et les frais se modifient en touchant leur ligne.

### Devises

- L'utilisateur ajoute ses devises, désigne la principale et saisit les taux de conversion, modifiables à tout moment.
- Chaque compte garde sa devise. La devise principale sert au suivi et de valeur proposée par défaut.
- Une opération dans une autre devise que celle de son compte est convertie vers la devise du compte. Le montant d'origine et le taux figé sont conservés.
- Une conversion passée ne change jamais.
- Les rapports peuvent convertir à une date choisie. Le total du patrimoine utilise les taux du jour.
- Changer de devise principale ne modifie que l'affichage et les rapports.
- Chaque devise indique si elle utilise des décimales. Le clavier de saisie affiche alors une virgule, ou sinon une touche « 000 » (par exemple pour le franc congolais).
- Dès qu'au moins un compte est dans une autre devise que la principale, l'écran Comptes montre en haut une icône d'affichage ; elle ouvre une feuille où choisir entre « Devise de chaque compte » et « Tout en <devise principale> (<code>) ». Sans autre devise, l'icône n'apparaît pas. Sous chaque compte figure le code de sa devise (USD, CDF, EUR…) ; un compte dans une autre devise montre en plus son équivalent approximatif en devise principale (« CDF · ≈ 30,00 $ »), un compte en devise principale rien de plus.

### Budgets

- Un budget par catégorie et par période, en devise principale. Les opérations en autre devise comptent selon leur taux figé.
- Le jour de début de période est réglable (par exemple le jour de paie).
- Pas de report du reste d'une période à l'autre.
- Les budgets s'affichent en tuiles (par défaut) ou en liste, triés selon l'attention requise (les plus consommés d'abord) ou dans l'ordre de l'utilisateur ; ces deux choix se font dans la feuille d'affichage, pas sur la page.
- Le détail d'un budget montre son évolution dans le mois (le total, ou au choix l'écart au rythme régulier), les opérations déjà prévues, et ses opérations rangées par jour.
- À la création, la moyenne dépensée dans la catégorie sur les mois passés est proposée comme repère, et les alertes à 80 % et 100 % sont activées d'avance.

### Récurrences

- Une récurrence crée directement l'opération par défaut. Un réglage global fixe ce comportement, et chaque récurrence peut le remplacer pour rester en brouillon.
- Si l'application n'a pas été ouverte le jour prévu, les occurrences manquées sont créées à leur date d'origine, avec une notification.
- Modifier une récurrence ne change que les occurrences futures.
- Rythme : chaque jour, semaine, mois ou année, avec un intervalle (par exemple toutes les 2 semaines). Fin au choix : jamais, après un nombre de fois, ou à une date.
- L'affichage de la liste des opérations (aussi dans Réglages, « Récurrences et brouillons ») règle trois choses : valider automatiquement ou toujours demander ; laisser les brouillons à leur date ou grouper en haut ceux en retard et du jour ; montrer à leur date ou masquer les opérations prévues du mois, qui ne sont jamais groupées.
- Un brouillon se valide ou s'ignore depuis la liste. Un brouillon ignoré ne compte pas ; il reste visible à sa date et ne peut plus être validé que depuis son détail.
- Une récurrence hebdomadaire peut tomber sur plusieurs jours de la semaine (par exemple le lundi et le jeudi), au moins un.

### Dettes et créances

- Contrepartie sous forme de simple nom, sans accès aux contacts du téléphone.
- Date d'échéance et remboursements partiels.
- Chaque mouvement peut être lié à un compte. Ce lien reste optionnel pour une dette ancienne.
- Pas de calcul d'intérêts.
- La liste se groupe par date d'échéance ou par personne, au choix de l'utilisateur.
- Les dettes et créances soldées restent par défaut dans leur mois, ou dans « Sans échéance » si elles n'avaient pas de date. L'utilisateur peut choisir de les regrouper en bas ou de les masquer (réglage d'affichage, aussi dans Réglages).

### Projets

- Chaque projet est rattaché à un compte, quel que soit son type (banque, mobile money, etc.). Un compte peut porter plusieurs projets.
- L'argent versé pour un projet reste dans le solde du compte, mais il est affiché à part comme réservé.
- La date d'un projet est facultative. Avec une date, l'application montre où il devrait en être aujourd'hui, son avance ou son retard, et un plan : le reste à mettre divisé en parts égales par semaine, quinzaine ou mois, au choix de l'utilisateur dans le réglage du projet, avec un rappel au même rythme. Sans date, le projet avance à son rythme.
- Quand l'objectif est atteint, l'utilisateur choisit : enregistrer la dépense (le projet se termine), garder l'argent de côté, ou le rendre disponible sur le compte. Les projets terminés restent consultables.

### Rappels et alertes

Notifications locales uniquement :

- rappel général de saisie, avec son heure, et alertes de budget à 80 % et 100 %, réglés dans Réglages ;
- délai par défaut avant une échéance, réglé dans Réglages ;
- rappel propre à chaque dette, créance, projet et récurrence, réglé dans sa fiche ;
- pour réclamer un remboursement, un message pré-rempli que l'utilisateur envoie lui-même par SMS ou WhatsApp.

Certaines marques Android retardent les notifications pour économiser la batterie : prévoir un guide de réglage et des tests sur ces appareils.

### Tableaux de bord

Graphiques simples. Détail d'affichage : [design/DIRECTION.md](design/DIRECTION.md).

- L'accueil (onglet « Accueil », titre « Aujourd'hui » suivi de la date) dit ce qui se passe et ce qui arrive, sans être lié à un mois. Dans l'ordre : le disponible (total des comptes moins la part réservée aux projets) ; le bilan du mois en cours, qui ouvre l'aperçu ; dettes et créances en deux cartes (total, nombre, retard) ; « À traiter », seulement s'il y a quelque chose (dette en retard, brouillons, budget presque atteint) ; « À venir » : les échéances des 14 prochains jours (dettes, créances, récurrences), montrées comme des opérations prévues, sous leur date, avec « Tout voir » vers la liste des opérations.
- « À traiter » rassemble ce qui demande une action, du plus urgent au moins urgent : dettes en retard, créances à réclamer, budgets dépassés, brouillons, échéances proches, budgets presque atteints, sauvegarde ancienne, projets en retard sur leur objectif, taux de change anciens. L'accueil en montre au plus 3, « Tout voir » ouvre la liste complète. Toucher une ligne ouvre le détail concerné ; toucher son action la fait directement, souvent dans une feuille pré-remplie (remboursement, message de réclamation par SMS ou WhatsApp, versement au projet, nouveau taux, sauvegarde lancée). Une action directe (valider des brouillons, lancer la sauvegarde, réclamer) montre toujours d'abord une synthèse, qu'on confirme ; pour les brouillons, on coche ceux à valider (tous d'avance) et toucher un brouillon ouvre sa fiche pour le modifier ou le valider seul ; la feuille ne modifie rien elle-même. Les autres actions (rembourser, mettre de côté pour un projet, modifier un taux) ouvrent la saisie habituelle, pré-remplie, qu'on enregistre soi-même. Une ligne traitée disparaît. On peut reporter une ligne d'un glissement (« Plus tard ») : elle revient le lendemain. Une créance réclamée reste, marquée « relancée le … », jusqu'au remboursement.
- L'aperçu montre une période au choix : aujourd'hui, hier, 24 heures, 7 jours, 1 mois (par défaut, selon le jour de début de période), 1 an, ou personnalisée. On passe à la période d'avant ou d'après de même longueur. Le regroupement proposé dépend de la période : par heure (aujourd'hui, hier, 24 h), par jour (7 jours), par jour ou semaine (1 mois), par mois ou semaine (1 an), au choix pour une période personnalisée. On compare à la période d'avant, d'après (si elle existe), à la période actuelle, ou à rien. La période et ses réglages sont gardés. L'aperçu a trois vues en onglets, qui partagent la même période : Évolution (sorties ou entrées dans le temps), Catégories (où part l'argent, d'où il vient ; une catégorie s'ouvre sur ses sous-catégories et ses opérations), Patrimoine (comptes plus créances moins dettes, dans le temps et par composante, et l'évolution de chaque compte).
- En bas de la vue Évolution, « Points suivis » : des tuiles choisies par l'utilisateur avec « Suivre » (dépensé, reçu, épargne, moyenne, catégorie n° 1, jour ou mois le plus cher, à venir, un budget, dettes, créances, un projet, comptes, patrimoine net), avec leur écart par rapport à la période comparée. Les 4 premières s'affichent, « Voir les autres » déplie le reste. Chaque tuile s'adapte à la période : pour un jour, dépensé se compare à une journée moyenne et « Reste pour aujourd'hui » apparaît ; pour une semaine, le jour le plus cher ; pour un an, l'épargne et la moyenne par mois. Une période personnalisée se règle sur sa longueur (jusqu'à 2 jours comme un jour, jusqu'à 2 semaines comme une semaine, au-delà comme un mois ou un an) ; les budgets restent mensuels et la tuile le dit. Les tuiles ne changent pas avec le choix Sorties ou Entrées. Toucher une tuile l'agrandit au premier plan, la page floutée derrière, avec plus de détails (graphique, repères, ce qui y contribue le plus, une action et « Tout voir ») ; on passe à la tuile voisine en glissant, et on ferme par un toucher à côté, le ✕, un glissement vers le bas ou le geste retour.

## Navigation et saisie

- Premier lancement : langue (celle du téléphone, déjà cochée, ou le français si le téléphone n'est ni en français ni en anglais), devise principale, premier compte, puis PIN et sauvegardes proposés sans être imposés. Dès le premier écran, « J'ai une sauvegarde » permet de restaurer ; la langue, la devise et les réglages viennent alors de la sauvegarde et les étapes suivantes sont sautées.
- Barre du bas : Accueil, Opérations, bouton **+** central qui dépasse vers le haut, Aperçu, Plus.
- « Plus » regroupe, dans l'ordre : Mes espaces (Comptes, Budgets, Projets, Dettes et créances, Récurrences, Catégories), puis Réglages et « Sauvegarde et export » (sauvegarde, restauration, export CSV), chacun sur une seule ligne, puis Aide et support, À propos, Noter Kibuo. Une sauvegarde trop ancienne se signale sur sa ligne, sans changer l'ordre de la page. Le profil viendra plus tard en tête de page.
- Les projets ont leur espace dans « Plus », et apparaissent aussi sous leur compte dans Comptes, avec la part réservée.
- Dettes et créances : section de l'accueil, bloc de l'aperçu, espace dans « Plus », et création depuis le +. Un remboursement s'enregistre depuis la fiche de la dette.
- Toucher le + ouvre la feuille « Ajouter » : Dépense en premier et en grand, puis Revenu, Transfert, Dette ou créance, et Projet (mettre de côté), chacun ouvrant sa saisie ; dessous, « Refaire » propose les dernières saisies, qui s'ouvrent pré-remplies. Maintenir le + ouvre un éventail des mêmes choix : on glisse vers l'un d'eux et on lève le doigt. Après quelques ouvertures du menu, une bulle fait découvrir l'appui long, une seule fois. Objectif : moins de 10 secondes pour une dépense.

## Protection des données

- Base de données chiffrée, verrouillage par PIN ou biométrie.
- PIN oublié : biométrie si active, sinon code de récupération, sinon effacement et restauration d'une sauvegarde.
- Sauvegardes automatiques **au choix de l'utilisateur** : hebdomadaires, dans un dossier choisi, avec un rappel si la dernière date trop.
- Fichier de sauvegarde versionné, chiffrement par mot de passe proposé mais optionnel.
- Restauration par remplacement complet, après une sauvegarde automatique de l'état actuel. Elle montre d'abord ce qui sera remplacé (période et nombre d'opérations) et se confirme par un appui long, sauf s'il n'y a rien à remplacer.
- Export CSV séparé.

## Après la V1

Voir [docs/backlog/](backlog/).
