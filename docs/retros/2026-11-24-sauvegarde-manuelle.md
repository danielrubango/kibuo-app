# Sauvegarde manuelle (24 novembre 2026)

Bilan de la branche `feat/manual-backup`, au moment de l'analyse : rien n'y est encore commité.

## Ce qui est fait

- **Les décisions** : le format du fichier est décrit dans l'ADR 0012. Il est en morceaux d'un mégaoctet, avec une enveloppe lisible et une base en clair dans le fichier, et un chiffrement par mot de passe en option. PRODUCT décrit la feuille, le dossier retenu, le nom du fichier, le seuil de 7 jours et ce que la sauvegarde emporte.
- **Le fichier** : `backup_file.dart` écrit et relit une sauvegarde. Un fichier abîmé, coupé ou dont la date a changé est refusé, et un mauvais mot de passe se distingue d'un fichier abîmé.
- **Le dossier** : le sélecteur de dossier d'Android, avec un droit d'écriture durable (`BackupFolders.kt`). Sa ligne iOS est notée dans `docs/backlog/ios.md`.
- **Les écrans** :
  - la feuille de sauvegarde, avec « Chiffrer avec un mot de passe », « Dossier introuvable » et la confirmation qui se ferme seule ;
  - la ligne « Sauvegarde et export » dans Plus, en ambre quand la sauvegarde est ancienne ;
  - la ligne « Sauvegarde » de « À traiter », avec « Lancer › ».
- **Le kit** : le champ de texte sait masquer ce qu'on tape, avec un œil pour l'afficher.
- **Les tests** : 21 de plus. Les 658 passent, et l'analyse est propre.

## Ce qui a bien marché

- Les règles pures (nom du fichier, âge, mot de passe prêt) sont séparées et testées à part.
- La feuille réutilise le kit : `NoticeCard`, `SwitchRow`, `KibuoButton`, la feuille de confirmation.
- Le choix Android est noté pour iOS dans la même change, comme le veut la règle.

## Ce qui reste fragile

- **Rien n'est commité** : 30 fichiers ne sont que sur le disque. Un changement de branche ou un nettoyage les emporterait.
- **Des copies de planches dans le dépôt** : `docs/design/boards/` (avec `sauvegarde-variantes.html`). Jusqu'ici, les planches vivaient seulement dans le canvas.
- **Pas encore de restauration** : une sauvegarde qu'on ne peut pas rouvrir ne protège encore de rien. Les planches RestauC1 à C3 existent.

## Ce qui se répète dans le code

Cette sauvegarde et la phase 5 ajoutent au même constat :

1. **Le format d'un montant** : dix écrans ont leur propre petite fonction `_money` qui appelle `formatMoney(m, currencyOf(m.currency), langue)`.
2. **La carte blanche** : une trentaine de `Container` blancs à coins de carte sont construits à la main, alors que le kit a déjà `KibuoCard`.
3. **La tuile d'icône teintée de 36** : huit copies (« À traiter », feuilles, formulaires, confirmation).
4. **Les jours de calendrier entre deux dates** : `backupAgeDays`, les dettes, les projets, « À traiter » et les budgets refont chacun le même calcul en `DateTime.utc`.
5. **« X sur Y »**, le grand montant suivi de son objectif : la page Projets, la fiche projet et la confirmation.

## Leçon

**Commiter dès qu'une étape tient debout, même avant validation**, sur sa branche : la validation décide de la fusion, pas du commit. Le travail resté hors commit est celui qu'on peut perdre ou écraser sans le voir.
