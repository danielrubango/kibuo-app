---
title: Fiche Google Play
milestone: Version 0.1
---

# Fiche Google Play

Textes et images de la fiche de kibuo dans la Play Console. On avance point par point, parce que certains choix en entraînent d'autres (décidé le 26 novembre 2026).

## Décidé le 26 novembre 2026

- **Nom** : « kibuo : budget et épargne » (25 caractères), en anglais « kibuo: budget & savings » (variante D parmi cinq, choisie par le propriétaire). « kibuo : budget, projets, épargne » dépasse les 30 caractères permis (32) ; sans virgules, il tiendrait mais se lirait comme une liste de mots-clés. Le mot « projets » est dans la brève description, juste sous le nom.
- **Brève description** (80 caractères au plus), le slogan :
  - fr : « Votre compagnon, des dépenses quotidiennes à vos projets, hors ligne. » (68)
  - en : « Your companion, from everyday spending to your plans, offline. »
- **Description complète** : les textes ci-dessous, sans annoncer ce qui viendra plus tard (Google refuse qu'une fiche promette ce que l'appli ne fait pas encore).
- **Icône** : celle de l'appli, en 512 × 512.
- **Données des captures** : un jeu de démonstration fait pour l'occasion (montants en francs congolais et en dollars, noms inventés), dans un utilisateur Android d'essai créé puis supprimé ; le profil de l'émulateur n'est pas touché.
- **Langues** : textes en français et en anglais dès la 0.1 ; captures en français d'abord, en anglais avant la publication.
- **Captures et image de présentation** : on commence simplement pour le test fermé ; trois styles de captures (A fond nuit, B fond clair, C écran seul) et des variantes de l'image de présentation sont à montrer sur le canvas, un point après l'autre.
- **Style des captures** : A, fond nuit, une phrase en haut, l'écran dans un cadre de téléphone (choisi parmi A, B, C). La barre d'état du téléphone est retirée et redessinée en tirets gris, pour ne montrer ni Android ni iPhone ; sinon, on remettrait la vraie barre de chaque système.
- **Série du test fermé** (proposée le 26 novembre 2026, à valider) : six captures, accueil, saisie d'une dépense, opérations du mois, budgets, dettes, projets, avec ces phrases :
  1. Ce que vous pouvez dépenser, d'un coup d'œil. / Votre disponible, le mois en cours et ce qui attend.
  2. Une dépense notée en quelques touches. / Le bouton + est toujours là, même sans connexion.
  3. Tout votre mois, jour après jour. / Entrées, sorties et ce qui reste.
  4. Des budgets qui vous préviennent à temps. / Une alerte quand une catégorie approche de sa limite.
  5. Ce que vous devez, ce qu'on vous doit. / Les échéances, les retards et les remboursements.
  6. Mettez de côté pour vos projets. / Voyage, moto, rentrée : voyez où vous en êtes.
- **Comment refaire les captures** : `flutter test tool/demo_backup_test.dart` écrit la sauvegarde de démonstration ; on la restaure sur un utilisateur Android d'essai neuf (STATE, Émulateur et Android) ; on prend les six écrans ; `python3 tool/play_screens.py <captures> <sortie>` compose les images en 1080 × 1920.
- **Plus tard, avant la production** (vers fin décembre 2026) : des captures qui accompagnent l'utilisateur, reliées entre elles par des flèches, avec des parties d'écran mises en avant, des textes et des chiffres ; trois propositions de huit captures selon ce qu'on veut mettre en avant. Elles suivront les nouveautés qui arrivent (ROADMAP).

Contraintes de Google Play pour les captures : 2 à 8 par appareil, et le grand côté ne peut pas dépasser deux fois le petit. Les captures brutes de l'émulateur (1080 × 2424) sont refusées : il faut composer des images, par exemple en 1080 × 1920.

## Description complète, français

```
kibuo tient vos comptes sur votre téléphone : vos dépenses du quotidien, vos budgets, ce que vous devez, ce qu’on vous doit et vos projets d’épargne. Sans compte à créer, et même sans connexion.

Suivez votre argent
• Comptes en plusieurs devises, francs congolais, dollars et autres, avec vos propres taux
• Dépenses, revenus et transferts, notés en quelques touches avec le bouton +
• Photo d’un reçu ou d’une facture jointe à l’opération
• Recherche et filtres par mois, compte ou catégorie

Prévoyez
• Budgets par catégorie, avec une alerte quand vous approchez de la limite
• Opérations qui reviennent (loyer, salaire, abonnements) et rappels
• Une alerte trois jours avant qu’un solde ne manque

Dettes, créances et projets
• Ce que vous devez et ce qu’on vous doit, avec les remboursements partiels
• Un message prêt à envoyer pour réclamer un remboursement
• Des projets d’épargne et leurs versements

Vos données restent chez vous
• Tout reste sur votre téléphone, dans une base chiffrée
• Verrou par code ou par empreinte
• Sauvegarde dans un fichier, protégée par mot de passe si vous le voulez, et restauration sur un autre téléphone
• Pas de compte, pas de publicité, rien n’est vendu
• Des statistiques anonymes, seulement si vous l’acceptez

En français et en anglais.

Une question, une idée ? Écrivez-nous à contact@kibuo.app.
```

## Description complète, anglais

```
kibuo keeps your accounts on your phone: your everyday spending, your budgets, what you owe, what you are owed and your savings projects. No account to create, and it works offline.

Follow your money
• Accounts in several currencies, Congolese francs, dollars and more, with your own rates
• Expenses, income and transfers, entered in a few taps with the + button
• A photo of a receipt or an invoice attached to the transaction
• Search and filters by month, account or category

Plan ahead
• Budgets by category, with an alert when you get close to the limit
• Transactions that come back (rent, salary, subscriptions) and reminders
• An alert three days before a balance runs short

Debts, money owed and projects
• What you owe and what you are owed, with partial repayments
• A message ready to send to ask for a repayment
• Savings projects and their deposits

Your data stays with you
• Everything stays on your phone, in an encrypted database
• Lock with a PIN or your fingerprint
• Backup to a file, password-protected if you like, and restore on another phone
• No account, no ads, nothing is sold
• Anonymous statistics, only if you agree

In French and English.

A question or an idea? Write to us at contact@kibuo.app.
```
