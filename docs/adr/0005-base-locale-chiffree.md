# Base locale chiffrée dès le départ

La base SQLite est chiffrée dès la V1 (SQLCipher, remplacé par SQLite3 Multiple Ciphers : voir l'[ADR 0010](0010-moteur-de-chiffrement.md)), avec une clé conservée dans le stockage sécurisé du système, car chiffrer plus tard des bases existantes serait risqué.

## Consequences

La clé reste sur l'appareil : un téléphone perdu sans sauvegarde signifie des données perdues. La sauvegarde système Android ne doit pas embarquer la base. Le code de récupération et les sauvegardes (optionnelles) sont les seuls recours.
