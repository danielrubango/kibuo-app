# Moteur de chiffrement, versions et copie des données par Android

L'ADR 0005 prévoyait SQLCipher. Le paquet Flutter qui l'apportait est abandonné depuis la version 3 du moteur SQLite pour Dart, qui compile désormais lui-même une version chiffrée : SQLite3 Multiple Ciphers. La base est donc gérée avec Drift sur ce moteur, ouverte par une clé brute de 32 octets tirée au hasard et gardée dans le coffre sécurisé d'Android ; la clé étant déjà aléatoire, aucune dérivation lente de mot de passe n'est nécessaire à chaque ouverture.

Chaque enregistrement porte un identifiant UUID v7, qui se trie par date de création, et une version tirée d'une horloge hybride : le temps en millisecondes complété d'un compteur, qui ne recule jamais, même si l'horloge du téléphone est déplacée. L'identifiant de l'appareil est gardé dans le coffre, hors de la base : une copie des données sur un nouveau téléphone y devient un nouvel appareil, jamais le même.

Tant que le code de récupération n'existe pas, Android n'a pas le droit de copier les données de Kibuo (sauvegarde Google ou transfert vers un nouveau téléphone) : sans la clé, qui ne quitte jamais le téléphone, la copie serait illisible. À l'étape du code de récupération, Kibuo gardera aussi une copie de la clé verrouillée par ce code ; la copie par Android sera alors permise, réglable par l'utilisateur, et le code permettra de rouvrir les données sur un nouveau téléphone ou après la perte de la clé.

## Considered Options

- Rester sur SQLCipher : il faudrait compiler et maintenir soi-même la bibliothèque pour Android et iOS, que plus aucun paquet maintenu ne fournit.
- Rendre le chiffrement de la base optionnel : écarté. Il ne coûte rien de visible, et basculer des données réelles entre chiffré et clair est l'opération risquée que l'ADR 0005 voulait éviter. Le choix laissé à l'utilisateur porte sur le mot de passe des sauvegardes et sur la copie par Android.
- Dériver la clé du PIN : écarté. Changer de PIN imposerait de tout rechiffrer, et un PIN de 4 à 6 chiffres est trop faible pour protéger seul la base.

## Consequences

Si la clé disparaît du coffre ou ne correspond plus, Kibuo affiche « Vos données ne peuvent pas être ouvertes », garde le fichier de côté sans l'effacer et propose de repartir de zéro ; la restauration d'une sauvegarde s'y ajoutera à son étape, puis la réouverture par le code de récupération. Le code de récupération, court (16 caractères), devra protéger la copie de la clé avec une dérivation lente et résistante aux essais en masse.

Mis en place le 15 novembre 2026 : la clé verrouillée par le code est rangée dans `kibuo-key.json`, à côté de la base (PBKDF2-HMAC-SHA256, 300 000 tours, sel neuf à chaque code ; 32 octets masquent la clé, 32 la signent pour reconnaître un code faux). Un agent de sauvegarde Android ne laisse copier que ces deux fichiers, et seulement quand un code existe et que « Laisser Android copier Kibuo » est actif.
