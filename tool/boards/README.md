# Planches du canvas

Les maquettes se dessinent sur le canvas de design, puis les planches retenues sont copiées dans [docs/design/boards/](../../docs/design/boards/). La méthode (variantes, page « En cours », raisons des écarts) est dans [WORKING.md](../../docs/WORKING.md#le-canvas-de-design).

## Le canvas

`https://claude.ai/artifact/1W89dFz4aodFsKmmKeJj9R`, un artifact de type Design (son titre dit encore « kibuo · Page de confidentialité »). Pages : « En cours », « Tuiles agrandies », « Google Play », « WhatsApp ». Ses fichiers sont sous `project/` : une planche par fichier `Nom.dc.html`, et `project/canvas.json`, qui place chaque planche (page, x, y, titre) et les titres de section (`notes`).

L'ancien canvas « Kibuo - Identité et directions » est dans une autre organisation : il ne s'ouvre plus depuis ce compte.

## Récupérer

Avec l'outil Artifact, `action: "read"` sur le lien, `paths: ["project/canvas.json", "project/CompteB.dc.html", …]` et `out_dir` sur un dossier de travail du scratchpad. Relire `canvas.json` juste avant de le publier : le propriétaire peut avoir déplacé des planches entre-temps (le compteur `edits` du canvas monte).

## Dessiner

`kit.py` donne les pièces : les couleurs de l'app lues dans `lib/ui/theme/kibuo_colors.dart` (`C['accent']`, `C['debtTint']`…), les icônes, la tuile, la barre de part, la carte, le haut d'une page poussée, le titre de groupe, et `shell`, qui fait le fichier complet de 390 × 844 au format du canvas. `write` l'écrit dans le dossier `project/`, `place` le pose dans `canvas.json`.

`jour.py` est l'exemple complet : les trois façons de montrer le jour sur la courbe d'un compte (J1, J2, J3).

```bash
python3 tool/boards/jour.py <dossier>/project
```

## Regarder

```bash
tool/boards/render.sh <dossier>/project/JourJ3.dc.html /tmp/JourJ3.png
```

Chrome dessine la planche comme le canvas ; lire l'image avant de publier.

## Publier

Avec l'outil Artifact, `action: "publish"` : `url` du canvas, `root` sur le dossier de travail (celui qui contient `project/`), `file_path` sur `project/canvas.json`, et `files` qui nomme les planches nouvelles ou changées (`{"project/JourJ3.dc.html": "project/JourJ3.dc.html"}`). Les fichiers non envoyés restent tels quels.

## Après le choix du propriétaire

- Le titre de chaque variante finit par « (retenue) » ou « (non retenue) » dans `canvas.json`, puis on republie.
- La planche retenue est copiée dans `docs/design/boards/`, avec sa ligne dans leur README.
- Les variantes écartées et leur raison (« raison non écrite » s'il n'en a pas donné) vont dans DIRECTION, « Variantes écartées et pourquoi ».
