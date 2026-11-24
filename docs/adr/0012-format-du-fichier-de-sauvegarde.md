# Format du fichier de sauvegarde

Une sauvegarde kibuo est un seul fichier `.kibuo`. Il commence par une enveloppe lisible sans mot de passe (version du format, date de la sauvegarde, chiffrée ou non). Le contenu suit, découpé en morceaux d'un mégaoctet : un résumé (date, version des tables, nombre de comptes, d'opérations et de projets), la base de données **en clair**, et les pièces jointes telles que kibuo les garde, déjà chiffrées avec leur clé rangée dans la base (ADR 0011).

La base en clair est une copie : SQLite3 Multiple Ciphers la recopie avec la clé du téléphone (`VACUUM INTO`), puis la copie, rattachée à part, est déchiffrée (`rekey` vers rien). Le fichier de la base du téléphone n'est jamais touché, et la copie de travail est effacée même après un échec. Ainsi une sauvegarde s'ouvre sur n'importe quel téléphone, sans la clé qui ne quitte jamais l'appareil (ADR 0010). Elle garde aussi sa version des tables : à la restauration, les migrations habituelles de Drift la mettront à jour.

Avec un mot de passe, chaque morceau est chiffré en AES-GCM avec une clé tirée du mot de passe par PBKDF2-HMAC-SHA256 (300 000 tours, sel neuf à chaque sauvegarde), comme le code de récupération. Une petite empreinte de la clé, rangée dans l'enveloppe, permet de distinguer un mauvais mot de passe d'un fichier abîmé. Sans mot de passe, chaque morceau porte une empreinte SHA-256. Dans les deux cas, chaque morceau est lié à l'enveloppe, à sa place et au fait d'être le dernier : un fichier modifié, coupé ou dont la date a été changée est refusé.

Le résumé porte aussi la langue de kibuo au moment de la sauvegarde (ajouté le 24 novembre 2026) : depuis Android 13, la langue choisie est gardée par Android et non dans la base, elle ne voyagerait pas sans cela ; une restauration la remet. Les sauvegardes plus anciennes n'ont pas ce champ et ne changent pas la langue.

Le dossier choisi et la date de la dernière sauvegarde sont gardés dans le coffre du téléphone, pas dans la base. Une restauration ne les change donc pas, et ils ne voyagent pas dans la sauvegarde. Le code, l'empreinte, la confidentialité et le code de récupération y sont déjà, propres à chaque téléphone.

## Considered Options

- Exporter chaque table en JSON : lisible, mais la restauration d'une sauvegarde ancienne demanderait de réécrire chaque migration pour ce format. La copie de la base profite des migrations existantes.
- Copier le fichier chiffré de la base avec sa clé : il faudrait mettre la clé de la base dans le fichier, ce qui revient à une sauvegarde en clair pour qui sait lire le format.
- Une archive zip : elle aurait demandé une dépendance de plus et la lecture de l'archive entière en mémoire pour la chiffrer. Le format maison reste simple et se lit morceau par morceau.

## Consequences

Sans mot de passe, quiconque obtient le fichier peut lire les données. « Chiffrer avec un mot de passe » est pourtant éteint par défaut, pour qu'une sauvegarde ne demande qu'un geste : la feuille le propose à chaque fois (PRODUCT). Un mot de passe oublié rend la sauvegarde définitivement illisible. Un changement du format augmente sa version dans l'enveloppe, et kibuo devra continuer de lire les versions précédentes.
