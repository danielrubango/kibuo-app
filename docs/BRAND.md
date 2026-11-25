# Marque

Nom retenu : **kibuo**, toujours en minuscules, y compris en début de phrase et sous l'icône du téléphone (validé le 17 novembre 2026). Nom inventé, inspiré de *kibubu*, la tirelire en swahili ; le sens est vérifié dans l'usage tanzanien, où il nomme aussi des produits d'épargne (Tigo Pesa Kibubu, comptes « Kibubu » de coopératives). Le 17 novembre 2026, kibuo a été gardé face à trois autres pistes (canvas NomChoix) : bombika (du lingala *kobomba*, garder), akibao (du swahili *akiba*, l'épargne) et tirelia (de « tirelire ») ; c'est le seul des quatre dont `.com` et `.app` sont libres et sans homonyme.

## Logo

[Logo retenu](design/logos/kibuo-logo.svg) : une tirelire menthe sur fond nuit, avec une pièce ambre qui entre dans la fente. Un petit tiret discret, sombre et à demi transparent, marque la pièce. Revu le 13 novembre 2026 face à quatre autres pistes (la fente, un K, un cochon, un pot kibubu) : la tirelire ronde reste. Le 14 novembre 2026, le grand cercle est placé au centre exact du dessin ; la pièce, un peu plus petite, ne dépasse du cercle que d'un tiers.

Icône Android adaptative : [fond](design/logos/kibuo-icon-background.svg) nuit plein, [premier plan](design/logos/kibuo-icon-foreground.svg) avec le dessin centré dans la zone sûre, et [version à une couleur](design/logos/kibuo-icon-monochrome.svg) pour les icônes à thème d'Android 13 et plus, où la fente et le bord de la pièce sont évidés. Le téléphone découpe l'icône en rond, en galet ou en carré arrondi ; le dessin reste lisible à 24 px.

Écrans de démarrage : Android 12 et plus affiche d'abord son propre écran, le [logo agrandi](../android/app/src/main/res/drawable/splash_icon.xml) sur le fond clair de l'application, sans texte ; Android 8 à 11 affiche le même logo à la même place. L'écran kibuo qui suit reprend le logo exactement au même endroit et à la même taille, puis ajoute le nom « kibuo » dessous.

Le nom dessiné (canvas NomMinusculeB) : « kibuo » en Space Grotesk gras, lettres très légèrement resserrées, le point du « i » remplacé par la pièce ambre du logo avec son bord encre. Il sert sur l'écran de démarrage, l'écran verrouillé et partout où le nom est montré seul ; dans une phrase, le nom s'écrit simplement « kibuo ».

## Icônes

Phosphor, pour sa version pleine qui marque l'onglet actif. Le paquet Flutter n'étant plus maintenu, les polices officielles d'icônes (licence MIT) sont intégrées à l'application.

## État des vérifications

Contrôlé le 9 novembre 2026 :

| Point | Résultat |
|---|---|
| Application du même nom sur Google Play et l'App Store | Aucune trouvée |
| `kibuo.com` | Aucun enregistrement |
| `kibuo.app` | Aucun enregistrement |
| Noms proches | Kibu, Kiboo et Kibuu, hors finance ; une marque « kibubu » déposée aux États-Unis |
| Revérifié le 17 novembre 2026 | `kibuo.com` et `kibuo.app` toujours libres ; aucune appli ni entreprise « kibuo » |

## À faire avant publication

- [ ] Chercher la marque auprès de l'OMPI, de l'EUIPO et de l'INPI
- [ ] Réserver `kibuo.com` et `kibuo.app` (achat par le propriétaire)
- [ ] Ouvrir la boîte `contact@kibuo.app` : À propos › Nous écrire y envoie depuis le 25 novembre 2026, et rien n'arrive tant que le domaine n'est pas pris
- [ ] Fixer l'identifiant Android à partir du domaine réservé ; il ne pourra plus changer après publication. Provisoire depuis la création de l'application : `app.kibuo`, tiré de `kibuo.app`
