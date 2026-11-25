---
title: Exigences de Google Play pour la version 0.1
milestone: Version 0.1
labels: [publication, google-play]
---

# Exigences de Google Play pour la version 0.1

Ce que Google Play demande aujourd'hui pour publier une première appli depuis un nouveau compte développeur personnel. Recherche faite le 25 novembre 2026, uniquement sur les pages officielles de Google (aide de la Play Console, developer.android.com, blog officiel Android Developers). La plupart des pages d'aide n'affichent pas de date de mise à jour : on le note « pas de date affichée ». Ce qui ne vient que d'une source secondaire est marqué **non vérifié**.

## En bref

### Ce que le propriétaire doit faire lui-même

- **Créer le compte** Play Console de type **personnel**, avec un compte Google, à 18 ans ou plus, et accepter le contrat de distribution.
- **Payer 25 dollars américains**, une seule fois, avec une carte à son nom (pas de carte prépayée).
- **Prouver son identité** : nom et adresse légaux, pièce d'identité officielle si le profil de paiement n'est pas déjà vérifié ; e-mail et téléphone de contact, et e-mail de développeur, confirmés par un code.
- **Savoir ce qui sera public** : pour un compte personnel, Google Play affiche le nom légal, le pays et l'e-mail de développeur.
- **Déclarer son statut de professionnel ou non** (« trader », lois de l'UE et du Royaume-Uni) dès la création du compte.
- **Vérifier un vrai téléphone Android** (Android 10 ou plus, non rooté) avec l'appli Play Console.
- **Recruter au moins 12 testeurs** avec un compte Google, qui restent inscrits au test fermé **14 jours d'affilée**.
- **Demander l'accès à la production** et répondre aux questions sur le test.
- **Garder la clé d'importation** (fichier et mots de passe) en lieu sûr, hors du dépôt.
- **Publier la politique de confidentialité** sur une page web publique (le site de kibuo, domaine à réserver).

### Ce qu'un agent peut préparer

- Le paquet AAB signé avec la clé d'importation, et la vérification de la cible API 36 et des pages mémoire de 16 Ko.
- La liste des autorisations du manifeste final, pour savoir quelles déclarations la Play Console demandera.
- Des brouillons pour la page « Contenu de l'application » : sécurité des données, classification du contenu, public cible, publicités, fonctionnalités financières, santé, applis gouvernementales, accès à l'appli.
- Les textes et captures de la fiche, et le texte de la politique de confidentialité pour le site.
- Un brouillon des réponses à la demande d'accès à la production, à partir des retours des testeurs.

## 1. Test fermé obligatoire avant la production

- **Qui** : les comptes personnels créés après le 13 novembre 2023.
- **Combien** : au moins **12 testeurs** dans un test fermé.
- **Combien de temps** : ces 12 testeurs doivent être inscrits **sans interruption pendant au moins 14 jours**, juste avant la demande. Au moment de la demande, 12 testeurs doivent être inscrits.
- **Comment on compte** : un testeur qui s'inscrit, teste moins de 14 jours puis se désinscrit ne compte pas. S'il revient, les 14 jours doivent être consécutifs. Il faut dire aux testeurs de rester inscrits 14 jours au moins.
- **Par appli** : la règle parle d'un test fermé « pour leur appli ».
- **Les testeurs** : ajoutés par liste d'e-mails ou par groupe Google ; chacun doit accepter le test par le lien d'inscription, qui n'apparaît que quand la version de test est publiée. Il leur faut un compte Google.
- **La demande** : depuis le tableau de bord de la Play Console, bouton « Apply for production ». Les questions portent sur trois points :
  - **le test fermé** : facilité à trouver des testeurs ; usage de toutes les fonctions ; usage des testeurs comparé à celui attendu en production, et les différences vues ; résumé des retours et façon de les recueillir ;
  - **l'appli** : public visé ; ce qu'elle apporte ; nombre d'installations estimé la première année ;
  - **la préparation** : changements faits après le test ; comment on a jugé l'appli prête.
- **Délai d'examen** : « habituellement sept jours ou moins », parfois plus.
- **Refus possible** : Google peut demander de continuer le test, par exemple s'il y a moins de 12 testeurs inscrits ou trop peu d'engagement.
- **Changements en 2025 et 2026** : les pages officielles consultées donnent 12 testeurs et 14 jours, sans historique. Le passage de 20 à 12 testeurs en décembre 2024 n'est écrit que dans un guide de la communauté Google Play (pas une page d'aide officielle) : **non vérifié**. L'annonce des règles du 29 octobre 2026 ne parle pas du test fermé.

Sources :

- [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Set up an open, closed, or internal test](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- Source secondaire, non officielle : [Everything about the 12 testers requirement](https://support.google.com/googleplay/android-developer/community-guide/255621488/everything-about-the-12-testers-requirement?hl=en), guide de la communauté Google Play, consulté le 25 novembre 2026.

## 2. Niveau d'API cible

- **Depuis le 31 août 2026** : les nouvelles applis et les mises à jour doivent cibler **Android 16 (API 36)** ou plus. Une prolongation jusqu'au 1er novembre 2026 pouvait être demandée ; cette date est passée.
- **Applis déjà publiées** : elles doivent cibler Android 15 (API 35) ou plus pour rester visibles des nouveaux utilisateurs sur les Android plus récents.
- **Prochaine échéance** : le blog officiel annonce que les nouvelles applis et les mises à jour devront cibler **API 37 (Android 17)** à partir d'**août 2027**. Le jour exact n'est pas donné.
- **kibuo** cible l'API 36 : c'est conforme aujourd'hui. Aucune page consultée n'impose de minimum pour l'API minimale (kibuo : Android 8, API 26).

Sources :

- [Target API level requirements for Google Play apps](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Meet Google Play's target API level requirement](https://developer.android.com/google/play/requirements/target-sdk), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Prepare your app for the resizability and orientation changes in Android 17](https://android-developers.googleblog.com/2026/02/prepare-your-app-for-resizability-and.html), blog Android Developers, publié le 13 février 2026, consulté le 25 novembre 2026.

## 3. Paquet AAB, signature par Google Play, clé d'importation

- **Format** : depuis août 2021, les nouvelles applis doivent être publiées en **Android App Bundle** (AAB), pas en APK.
- **Signature par Google Play** (Play App Signing) : obligatoire pour les applis créées depuis août 2021. Google garde la **clé de signature de l'appli** et signe ce que reçoivent les téléphones. Une nouvelle appli est inscrite d'office, avec une clé créée par Google. On ne peut pas récupérer une copie de cette clé.
- **Ce que le développeur crée et garde** : une **clé d'importation**, dans un fichier keystore Java (`.jks`), clé RSA de 2048 bits ou plus, avec un mot de passe. Elle signe chaque AAB envoyé. Google conseille une validité d'au moins 25 ans, et la clé doit rester valide après le 22 octobre 2033.
- **Si la clé d'importation est perdue ou volée** : on n'est pas bloqué. On crée une nouvelle clé, on exporte son certificat (fichier PEM), puis on demande une « réinitialisation de la clé d'importation » dans la Play Console (page de signature de l'appli). Les pages consultées ne donnent pas le délai de traitement.
- **Pour comparaison** : celui qui gère lui-même sa clé de signature et la perd ne peut plus publier de mise à jour.

Sources :

- [Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Sign your app](https://developer.android.com/studio/publish/app-signing), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [About Android App Bundles](https://developer.android.com/guide/app-bundle), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/7384423?hl=en) (section sur la réinitialisation), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.

## 4. Identité du développeur, frais, vérification Android

### Création du compte

- **Frais** : **25 dollars américains**, une seule fois. Cartes acceptées : Mastercard, Visa, American Express, Discover (États-Unis seulement), Visa Electron (hors États-Unis). Pas de carte prépayée ; l'acceptation varie selon le pays.
- **Âge** : 18 ans au moins.
- **Informations demandées (compte personnel)** : nom de développeur (peut différer du nom légal), nom légal, adresse légale, e-mail et téléphone de contact (pour Google, non publics), e-mail de développeur (public), statut de professionnel là où la loi l'exige. E-mail et téléphone de contact, et e-mail de développeur, sont confirmés par un code à usage unique et doivent rester valides.
- **Ce qui est public** : le nom légal, le pays (tiré de l'adresse) et l'e-mail de développeur. L'adresse complète aussi si l'appli rapporte de l'argent.
- **Vérification d'identité** : Google peut demander une pièce d'identité officielle et une carte bancaire, toutes deux au nom légal. Il faut être vérifié avant de soumettre une appli.
- **Vérification d'un appareil** : les nouveaux comptes personnels doivent prouver l'accès à un **vrai téléphone Android**, non rooté, sous **Android 10 ou plus**, avec l'appli Play Console, avant de publier. Cela prend en général moins d'une minute ; le numéro de téléphone de l'appareil n'est pas collecté.
- **D-U-N-S** : demandé seulement aux comptes d'**organisation**.

### Vérification des développeurs Android (programme annoncé en 2025)

- **Ce que c'est** : sur les téléphones Android certifiés (Android 8 et plus), une appli doit venir d'un développeur vérifié et être enregistrée (nom de paquet) pour s'installer.
- **Calendrier** : depuis le **30 septembre 2026** au Brésil, en Indonésie, à Singapour et en Thaïlande, pour les boutiques participantes ; **extension mondiale en 2027**.
- **Pour une appli publiée sur Google Play** : la plupart des développeurs Play n'ont **rien de plus à faire** pour l'identité : la vérification de la Play Console suffit. Quand on crée une appli dans la Play Console, le nom de paquet est **enregistré automatiquement** et lié au compte. Les applis qui utilisent la signature par Google Play sont réclamées automatiquement.
- **Comptes à distribution limitée** (20 appareils, sans pièce d'identité ni frais) : prévus pour étudiants et amateurs ; sans objet pour une publication sur Google Play.

### Statut de professionnel (trader)

- Tout compte actif doit déclarer s'il est **professionnel** ou **non professionnel** au sens des lois de l'UE et du Royaume-Uni, au plus tard le **1er février 2027** ; un **nouveau compte** le déclare dès sa création.
- Un professionnel avec un compte personnel verra son **téléphone et son adresse affichés** sur Google Play.
- Un non-professionnel : les consommateurs de l'UE et du Royaume-Uni seront informés que les droits du consommateur ne s'appliquent pas. Une activité de loisir non commerciale rend peu probable le statut de professionnel. Google ne tranche pas à la place du développeur.

Sources :

- [Get started with Play Console](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Required information to create a Play Console developer account](https://support.google.com/googleplay/android-developer/answer/13628312?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Verify your developer identity information](https://support.google.com/googleplay/android-developer/answer/10841920?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Device verification requirements for new developer accounts](https://support.google.com/googleplay/android-developer/answer/14316361?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Android developer verification](https://developer.android.com/developer-verification), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Google Play Console guide (developer verification)](https://developer.android.com/developer-verification/guides/google-play-console), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Android developer verification FAQ](https://developer.android.com/developer-verification/guides/faq), developer.android.com, consulté le 25 novembre 2026 ; chaque réponse a sa date (de septembre 2025 au 10 novembre 2026).
- [Trader status declaration](https://support.google.com/googleplay/android-developer/answer/17594752?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.

## 5. Fiche et page « Contenu de l'application »

- **Politique de confidentialité** : obligatoire pour toutes les applis, même sans données. Un lien dans le champ prévu de la Play Console, **et** un lien ou le texte dans l'appli. L'adresse doit être **une page web publique, active, accessible de partout** (pas de blocage par pays), **pas un PDF**, et non modifiable par le public. Elle doit nommer l'appli ou l'entité de la fiche, être titrée comme politique de confidentialité, et dire : qui contacter, quelles données sont collectées et partagées et avec qui, comment elles sont protégées, combien de temps elles sont gardées et comment les supprimer. La règle accepte « le texte dans l'appli » : rien dans les pages consultées n'interdit que ce soit le même texte que sur le site.
- **Sécurité des données** (Data safety) : formulaire obligatoire pour toutes les applis, même sans collecte ; il demande la politique de confidentialité. Détail au point 6.
- **Classification du contenu (IARC)** : questionnaire obligatoire pour chaque appli. Une appli sans classification est retirée. On le refait quand le contenu change.
- **Public cible et contenu** : déclarer les tranches d'âge visées. Si des moins de 13 ans sont visés, les règles « Familles » s'appliquent. Avant ce volet, il faut avoir rempli publicités, accès à l'appli et politique de confidentialité.
- **Publicités** : déclarer si l'appli contient des publicités ; mentir est une infraction. kibuo n'en a pas.
- **Applis gouvernementales** : la page dit que les développeurs doivent remplir cette déclaration sur la page « Contenu de l'application » (depuis le 31 janvier 2023). kibuo n'est pas une appli d'un gouvernement.
- **Fonctionnalités financières** : **toutes** les applis publiées (test fermé compris) remplissent la déclaration. Choix proposés : banque et prêts, paiements et transferts, achats à crédit et points, crypto et bourse, et services (suivi de crédit, conseil financier, assurance, autre). Il existe la réponse « Mon appli ne propose aucune fonctionnalité financière ». Le budget personnel n'est **pas** cité dans la liste. Voir « À vérifier ».
- **Santé** : **toutes** les applis remplissent la déclaration ; une appli sans fonction de santé le certifie.
- **Actualités** : seulement les applis de la catégorie « Actualités et magazines » ou qui se présentent comme telles. kibuo n'est pas concernée.
- **Suppression de compte** : exigée **seulement si l'appli permet de créer un compte**. Alors il faut un moyen dans l'appli et une page web, dont le lien va dans la Play Console. kibuo n'a pas de compte. La case « mon appli ne permet pas de créer de compte » dans le formulaire n'est décrite que par une source secondaire : **non vérifié**.
- **Accès à l'appli pour l'examen** : à remplir quand une partie de l'appli est fermée par une connexion, un abonnement, un lieu ou une autre authentification. La page précise : si l'utilisateur crée lui-même son code ou mot de passe, donner des instructions claires pour le créer. Instructions en anglais.

Sources :

- [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Content Ratings](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Manage target audience and app content settings](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Requirements for apps that communicate government information](https://support.google.com/googleplay/android-developer/answer/9514050?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Provide information for the Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Financial Services](https://support.google.com/googleplay/android-developer/answer/9876821?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Provide information for the Health apps declaration form](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [How to declare a news and magazine app](https://support.google.com/googleplay/android-developer/answer/16189314?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Understanding Google Play's app account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Requirements for providing sign in details for review](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Play Console Requirements](https://support.google.com/googleplay/android-developer/answer/10788890?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- Source secondaire, non officielle : [About the Data Safety Form and Account Deletion](https://support.google.com/googleplay/android-developer/community-guide/246344978/about-the-data-safety-form-and-account-deletion?hl=en), guide de la communauté Google Play.

## 6. Formulaire « Sécurité des données » pour la mesure d'usage avec accord

Ce que disent les définitions de Google, appliquées à kibuo (événements d'usage et rapports d'erreur envoyés à PostHog Europe après un « oui », avec un identifiant tiré au hasard, sans compte).

- **Collecte** : « collecter » veut dire envoyer des données hors du téléphone. Les données qui restent sur le téléphone ne se déclarent pas. Les envois à PostHog sont donc une **collecte**, même s'ils sont facultatifs. Les données pseudonymes se déclarent aussi.
- **Types de données** concernés selon les définitions de Google :
  - **Interactions avec l'appli** : « comment l'utilisateur interagit avec l'appli » (par exemple le nombre de visites d'une page).
  - **Journaux de plantage** : nombre de plantages, traces de pile, autres informations de plantage.
  - **Diagnostics** : performances de l'appli (autonomie, temps de chargement, latence…), seulement si kibuo en envoie.
  - **Identifiants de l'appareil ou autres** : « identifiants liés à un appareil, un navigateur ou une appli » ; l'exemple de Google inclut l'identifiant d'installation Firebase. Un identifiant au hasard propre à l'installation entre dans cette définition. La page ne parle pas des identifiants tirés au hasard en tant que tels.
- **Partage** : transmettre à un **prestataire** (« service provider ») qui traite les données **pour le compte du développeur** n'est **pas** un partage. Les données entièrement anonymisées non plus.
- **Facultatif** : on peut déclarer une collecte facultative si **tous** les utilisateurs, quel que soit l'appareil ou le pays, peuvent l'accepter ou la refuser.
- **Traitement éphémère** : seulement si les données restent en mémoire, le temps de la requête. Des données gardées par PostHog ne sont pas éphémères.
- **Finalités** : « Analyse » couvre la façon dont les gens utilisent l'appli et comment elle fonctionne.
- **Chiffrement en transit** : le formulaire demande si toutes les données collectées sont chiffrées pendant le transfert (TLS ou HTTPS). La règle sur les données demande d'ailleurs d'envoyer les données sensibles avec une cryptographie moderne, par exemple HTTPS.
- **Demande de suppression** : le formulaire demande si l'utilisateur peut demander la suppression de ses données ; aucun moyen n'est imposé, mais il doit être facile à trouver.
- **Modules tiers** : ce qu'un module envoie compte comme ce que l'appli envoie. kibuo envoie elle-même, sans module PostHog (ADR 0013).
- **Information bien visible et accord** (prominent disclosure) : exigée quand l'accès, la collecte ou le partage de données personnelles « peut ne pas correspondre à ce que l'utilisateur attend raisonnablement ». La règle ne prévoit pas d'exception pour la mesure d'usage ou les rapports d'erreur. Quand elle s'applique, il faut, **dans l'appli** et pendant l'usage normal (pas seulement dans un menu ou la politique) : dire quelles données, à quoi elles servent, sans mélanger avec d'autres sujets ; puis un accord par un geste clair (bouton ou case) ; quitter, revenir en arrière ou toucher ailleurs ne vaut pas accord ; rien n'est collecté avant l'accord.

Sources :

- [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en), aide Play Console, consulté le 25 novembre 2026 ; dernière entrée de son historique : 5 décembre 2023.
- [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.

## 7. Autorisations et déclarations

- **Ne demandent aucune déclaration** dans la Play Console d'après la liste officielle des autorisations sensibles : `USE_BIOMETRIC`, `RECEIVE_BOOT_COMPLETED`, `INTERNET`, `POST_NOTIFICATIONS`. Règle générale : ne demander que les autorisations nécessaires aux fonctions présentes.
- **Notifications** (`POST_NOTIFICATIONS`) : depuis Android 13, autorisation demandée à l'utilisateur pendant l'usage ; les notifications sont coupées par défaut après une nouvelle installation.
- **Alarmes exactes** :
  - `USE_EXACT_ALARM` : accordée d'office, mais Google Play ne l'accepte que si la fonction principale de l'appli exige une heure précise, par exemple une appli de réveil ou de minuteur, ou un agenda qui notifie les événements. Il faut une déclaration dans la Play Console ; sinon l'appli est refusée. Les rappels ne sont pas cités.
  - `SCHEDULE_EXACT_ALARM` : accordée par l'utilisateur (« Alarmes et rappels »), pas accordée d'avance aux nouvelles installations d'applis ciblant Android 13 ou plus. Google la propose comme alternative pour les autres cas.
  - La documentation Android dit que la plupart des applis peuvent utiliser des alarmes **inexactes** ; pour « une action choisie par l'utilisateur après une heure donnée, même en veille », elle conseille une alarme inexacte (`setAndAllowWhileIdle`).
- **Service au premier plan** : pour les applis ciblant Android 14 ou plus, la Play Console demande de déclarer **chaque type de service au premier plan utilisé** (description, effet d'une interruption, vidéo). WorkManager ne lance un service au premier plan que pour les tâches longues (`setForeground`) ; dans ce cas, un type doit être déclaré. La page de Google ne dit rien d'un service déclaré par un module mais jamais utilisé : voir « À vérifier ».
- **Photos et vidéos** : `READ_MEDIA_IMAGES` et `READ_MEDIA_VIDEO` ne sont permises que si le sélecteur du système ne suffit pas ; seuls ceux qui les gardent font une déclaration. Application complète depuis le 28 mai 2025. Le manifeste de kibuo retire ces autorisations.

Sources :

- [Permissions and APIs that Access Sensitive Information](https://support.google.com/googleplay/android-developer/answer/9888170?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Developer Program Policy](https://support.google.com/googleplay/android-developer/answer/18265346?hl=en), aide Play Console, en vigueur depuis le 29 octobre 2026, consulté le 25 novembre 2026.
- [Permissions and APIs that Access Sensitive Information, partie sur l'alarme exacte](https://support.google.com/googleplay/android-developer/answer/13161072?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Schedule alarms](https://developer.android.com/develop/background-work/services/alarms), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Understanding foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Support for long-running workers](https://developer.android.com/develop/background-work/background-tasks/persistent/how-to/long-running), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Understanding Restricted Permissions with minimum scope alternatives](https://support.google.com/googleplay/android-developer/answer/14115180?hl=en) (photos et vidéos), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.

## Autres exigences trouvées en chemin

- **Pages mémoire de 16 Ko** : les applis qui contiennent du code natif doivent fonctionner sur les téléphones à pages de 16 Ko ; une appli Flutter contient du code natif. À partir du **1er février 2027**, une mise à jour non compatible ne pourra plus être publiée.
- **Qualité technique** : seuils actuels de 1,09 % de plantages et 0,47 % d'ANR (blocages) au total ; nouveaux seuils de mémoire à partir de février 2027 ; optimisation du code DEX seulement au-delà de 10 Mo de code.
- **Règles à venir pour l'API 37** (janvier et août 2027) : bouton de localisation, réseau local, contacts. Aucune ne concerne les fonctions actuelles de kibuo.

Sources :

- [Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Play Console technical quality requirements](https://support.google.com/googleplay/android-developer/answer/17492799?hl=en), aide Play Console, consulté le 25 novembre 2026, pas de date affichée.
- [Google Play Policies](https://developer.android.com/distribute/play-policies), developer.android.com, consulté le 25 novembre 2026, pas de date affichée.
- [Policy announcement: October 29, 2026](https://support.google.com/googleplay/android-developer/answer/18100766?hl=en), aide Play Console, consulté le 25 novembre 2026.

## À vérifier

- **Compte personnel et fonctions financières** : la page des exigences de la Play Console demande un compte d'**organisation** pour les « produits et services financiers, y compris mais pas seulement la banque, les prêts, la bourse, les fonds, les portefeuilles et plateformes de crypto ». La règle « Financial Services » définit ces produits comme ceux « liés à la gestion ou à l'investissement de l'argent ». Aucune page officielle ne dit si une appli de budget personnel, sans paiement ni prêt ni lien bancaire, en fait partie. La liste de la déclaration ne cite pas le budget. À confirmer en ouvrant la déclaration dans la Play Console, ou auprès de l'aide Google.
- **Passage de 20 à 12 testeurs** (décembre 2024) : seulement dans un guide de la communauté. Non vérifié, sans effet sur la règle actuelle (12).
- **Délai de réinitialisation de la clé d'importation** : non indiqué dans les pages consultées.
- **Case « l'appli ne permet pas de créer de compte »** du formulaire sur la sécurité des données : décrite par une source secondaire seulement ; à voir dans la Play Console.
- **Accès à l'appli avec le code optionnel** : la page parle des codes créés par l'utilisateur ; elle ne dit pas si un verrou facultatif, qui ne ferme aucune fonction, demande des instructions. À voir dans le formulaire.
- **Service au premier plan de WorkManager** : la page de Google ne dit pas si la Play Console demande une déclaration quand le service vient d'un module et n'est jamais lancé. À vérifier dans le manifeste final et à l'envoi du premier AAB.
- **Identifiant publicitaire** : la page officielle consultée parle de l'autorisation `AD_ID` pour les applis ciblant Android 13, mais pas clairement de la déclaration dans la Play Console. À vérifier à l'envoi.
- **PostHog comme prestataire** : l'exception de « partage » vaut pour un tiers qui traite les données pour le compte du développeur ; vérifier que le contrat de PostHog (accord de traitement des données) le dit.
- **Ce que kibuo envoie vraiment** : vérifier si des mesures de performance partent (type « Diagnostics ») et si PostHog garde l'adresse IP.
- **Gratuité du questionnaire IARC** : la page ne parle pas de coût.
- **Révision des versions de test fermé** : la page sur les tests ne dit pas si elles sont examinées avant d'être disponibles.

## Ce que cela veut dire pour kibuo

- Compter au moins **14 jours de test fermé** avec **12 testeurs** inscrits sans interruption, puis jusqu'à **7 jours** d'examen de la demande, avant la publication en production.
- La cible **API 36** est conforme ; l'API 37 sera exigée en août 2027.
- Il faut passer à un **AAB** signé par une **clé d'importation**, que le propriétaire garde ; Google garde la clé de signature.
- Le **Poco X3 NFC** peut servir à vérifier l'appareil s'il n'est pas rooté.
- La **politique de confidentialité** doit être en ligne sur une page web publique (pas un PDF) avant de remplir le formulaire sur la sécurité des données ; le texte dans l'appli peut rester.
- Le formulaire sur la sécurité des données déclare une collecte **facultative** : interactions, plantages, identifiant de l'appareil, éventuellement diagnostics, pour l'**analyse**, chiffrée en transit, et sans partage si PostHog agit pour le compte de kibuo.
- Les déclarations « fonctionnalités financières », « santé » et « applis gouvernementales » se remplissent même si la réponse est « aucune ».
- Pas de compte, donc pas de page de suppression de compte exigée.
- Avant d'ajouter une alarme exacte pour les rappels : `USE_EXACT_ALARM` n'est pas prévue pour cet usage d'après la règle ; `SCHEDULE_EXACT_ALARM` ou une alarme inexacte restent possibles.
- Vérifier la compatibilité **16 Ko** de l'AAB avant le 1er février 2027.
