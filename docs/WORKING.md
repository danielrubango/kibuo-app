# Travailler avec le propriétaire de kibuo

Ce document dit **comment** on travaille sur kibuo. Ce qui est livré et ce qui vient ensuite est dans [STATE.md](STATE.md) ; les règles de code sont dans [AGENTS.md](../AGENTS.md).

## Le propriétaire

- Il ne lit ni le Dart, ni le Kotlin, ni le Swift. Les agents écrivent le code ; les tests et son essai sur l'appareil sont le contrôle qualité.
- **Toujours lui répondre en français**, en termes de ce qu'il voit et peut essayer sur le téléphone (« touche Plus › Sauvegarde et export »), jamais en termes de classes ou de fichiers, sauf s'il le demande.
- Il juge en regardant : on lui montre des captures, des planches, des variantes côte à côte, pas de longs textes.
- Le nom de l'app s'écrit **kibuo**, en minuscules partout, même en début de phrase.

## Le cycle d'une étape

Le skill du dépôt `/next-step` (`.claude/skills/next-step/SKILL.md`) décrit le cycle ; en clair :

1. **Orienter** : prendre la première case vide de [ROADMAP.md](ROADMAP.md), lire la section de [PRODUCT.md](PRODUCT.md), les ADR concernées et [GLOSSARY.md](../GLOSSARY.md).
2. **Questionner avant de coder** : poser les décisions ouvertes en questions numérotées (Q1, Q2…), chacune avec une recommandation (format « ❓ Q1 … ➡️ recommandation »). Attendre ses réponses. Écrire les décisions dans PRODUCT (ou DIRECTION, ou une ADR) **avant** de coder.
3. **Brancher** : une branche par livraison, depuis `main` à jour : `feat/…`, `fix/…`, `docs/…`, `design/…`, `chore/…`, `refactor/…`.
4. **Prouver d'abord** : pour la logique critique (soldes, conversions, récurrences, sauvegarde et restauration, migrations), écrire le test, le voir échouer pour la bonne raison, puis coder.
5. **Construire**, puis `tool/check.sh`.
6. **Parcourir sur l'émulateur soi-même** avant de montrer (voir plus bas), comparer avec la planche validée.
7. **Montrer** : captures et liste de ce qu'il peut essayer.
8. **Fusionner après sa validation** (« je valide, fusionne »). Il pousse lui-même `main` (voir Git).

Les grosses étapes se livrent en plusieurs **livraisons** validées l'une après l'autre (ex. Projets en trois temps).

## Les règles qu'il a posées

- **Le design validé fait foi.** Toute adaptation hors des planches validées, et tout cas où la logique d'une planche semble fausse, lui est proposé (avec une recommandation) et attend son « oui » explicite avant de toucher au code. Fidélité « à tout niveau » : couleurs, intensités, placements, typographie, marges.
- **Mesurer la planche avant de coder un écran** : lire le HTML de la planche ([design/boards/](design/boards/)), noter chaque mesure (largeurs, marges, tailles, couleurs, états) et comparer l'écran construit ligne à ligne. Quand un élément apparaît sur plusieurs planches (barre, carte, ligne, montant), le mesurer sur toutes et lui poser la question en cas d'écart. À la deuxième apparition d'un élément, en faire un composant du kit.
- **Parcourir chaque étape sur l'émulateur** avant de la lui montrer (il a souvent trouvé des défauts d'espacement que les seuls tests ne montraient pas).
- **Ne jamais effacer les données de l'app sur l'émulateur sans lui demander** : pas de `adb shell pm clear app.kibuo`, pas de désinstallation, rien qui efface ses comptes de test. Pour rejouer une astuce qui ne s'affiche qu'une fois, écrire un test de widget, ou utiliser l'utilisateur Android d'essai (plus bas).
- **Son téléphone** : ne jamais désinstaller l'app (cela effacerait ses vraies données). Installer seulement en mise à jour, après le parcours sur l'émulateur.
- **Commiter seul, vérifier, puis fusionner** : `git commit` dans sa propre commande, lire `git log -1` (le hook pre-commit peut refuser), puis seulement `git checkout main && git merge`. Ne jamais enchaîner commit et fusion dans une seule commande.
- **Commiter dès qu'une étape tient debout**, sur sa branche, même avant validation : la validation décide de la fusion, pas du commit (leçon de la sauvegarde manuelle, [retro 2026-11-24](retros/2026-11-24-sauvegarde-manuelle.md)).
- **Dates des tests à minuit** : une opération de test datée « aujourd'hui » se met à 00:00, jamais à 9 h (après minuit, une opération de 9 h est dans le futur et les filtres de date l'écartent).
- **Rétro** quand il la demande (`/retro`) : un fichier `docs/retros/AAAA-MM-JJ-sujet.md` (ce qui a marché, ses retours, composants, leçons).

## Le canvas de design

Le design se fait sur un artifact « Design » de claude.ai (« Kibuo - Identité et directions »), exporté dans [design/boards/](design/boards/). Un autre agent sans ce canvas reprend la méthode dans un nouveau canvas :

- Il demande **2 ou 3 variantes nommées** (A, B, C), côte à côte. Il en choisit une, souvent avec des variantes de la variante (A1, A2…). Garder les variantes non retenues jusqu'à ce qu'il dise « nettoyer ».
- Le travail en cours vit sur la page **« En cours »** ; une planche validée part sur la page de son domaine (Accueil, Opérations, Réglages…).
- Chaque règle validée s'écrit dans [PRODUCT.md](PRODUCT.md) ou [design/DIRECTION.md](design/DIRECTION.md) dans la même étape, avec sa date.
- Quand il écarte une variante, sa raison s'écrit le jour même dans DIRECTION, section « Variantes écartées et pourquoi » (décidé le 24 novembre 2026). On ne reconstitue pas de mémoire une raison qui n'a pas été notée.
- Les planches ont un titre qui dit ce qu'elles montrent ; « retenue » / « non retenue » sur la page En cours.

## Environnement

| Quoi | Valeur |
|---|---|
| Flutter | 3.47.9, canal stable, Dart 3.13.7, installé par fvm (`~/fvm/default/bin` dans le PATH) |
| Émulateur | AVD `Pixel_10_Kibuo`, en anglais, `emulator-5554` |
| Utilisateur Android d'essai | `kibuo-essai` (id 10) sur l'émulateur, pour tester un premier lancement sans toucher au profil principal ; gardé jusqu'à la fin de la phase 6, puis supprimé avec l'accord du propriétaire (décidé le 24 novembre 2026) |
| Téléphone du propriétaire | Xiaomi Poco X3 NFC (M2007J20CG), Android 15, série adb `abe5999d` |
| Dépôt de l'app | https://github.com/danielrubango/kibuo-app (`origin`), privé |
| Dépôt serveur | https://github.com/danielrubango/kibuo-api : le futur serveur de synchro (Laravel) et le site public (confidentialité, conditions, suppression de compte, contact), voir [backlog/site-public.md](backlog/site-public.md) |

Les commandes exactes (lancer l'émulateur, construire, installer, l'utilisateur d'essai) sont dans [AGENTS.md](../AGENTS.md).

### Avec deux appareils branchés

Chaque commande `adb` prend `-s emulator-5554` ou `-s abe5999d`.

### Git et push

Le propriétaire pousse lui-même `main` : à la fin d'une fusion, lui donner la commande `cd /Users/mac/Documents/Herd/kibuo && git push origin main` (le push par l'agent a été bloqué par le mode automatique).

## Skills

Les skills de **Claude Code** sont globaux sur l'ordinateur du propriétaire (`~/.claude/skills/`), sauf `next-step` qui est dans le dépôt. Codex ne les exécute pas ; voici ce qu'ils font, pour reproduire leur méthode.

| Commande | Ce qu'elle fait |
|---|---|
| `/next-step` (dépôt) | Le cycle d'une étape de la roadmap, décrit plus haut. |
| `/grill-me`, `/grilling` | Questions par tours : chaque tour pose toutes les décisions dont les prérequis sont tranchés, numérotées, avec une recommandation ; on attend les réponses avant le tour suivant ; on ne code pas avant qu'il confirme. Les faits se vérifient soi-même dans le dépôt, seules les décisions lui sont posées. |
| `/componentize` | Repérer ce qui se répète dans l'interface et l'extraire en composants du kit (`lib/ui/kit/`), sans changer le rendu ; les marges restent à l'appel, pas dans le composant. |
| `/design` | Construire une interface nouvelle selon un guide de design (ui.sh) ; ici, l'appliquer au système de [design/SYSTEM.md](design/SYSTEM.md). |
| `/ideas` | Montrer plusieurs variantes d'une interface pour qu'il choisisse ; ici, des variantes côte à côte sur le canvas. |
| `/retro` | Une rétrospective de la séance, écrite dans `docs/retros/`. |
| `/code-review` | Relire un ensemble de changements sur deux axes : respect des règles du dépôt, et conformité à la demande. |
| `/tdd` | Le test d'abord : rouge, vert, puis nettoyage. |
| `/writing-for-agents` | Écrire les documents lus par les agents (CLAUDE.md, AGENTS.md, skills). |
| `/domain-modeling` | Tenir le glossaire et les ADR quand on nomme un concept ou prend une décision durable. |
