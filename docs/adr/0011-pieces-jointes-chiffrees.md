# Pièces jointes chiffrées à côté de la base

Les pièces jointes (photo d'un reçu, PDF) sont rangées comme fichiers dans le dossier privé de Kibuo (`attachments/`), chacune chiffrée en AES-GCM avec une clé tirée au hasard au premier usage et conservée dans la base chiffrée. La base ne garde que leur fiche (nom, type, poids, opération).

Les ranger dans la base l'alourdirait à chaque photo et ralentirait les sauvegardes et la synchronisation ; les laisser en clair contredirait « Vos données sont chiffrées » (ADR 0005). Garder la clé dans la base plutôt que dans le stockage sécurisé du téléphone fait qu'elle voyage avec elle : le code de récupération, la copie Android et les sauvegardes ouvrent aussi les pièces jointes, sans clé de plus à protéger.

## Consequences

Les photos sont réduites à 1 600 pixels avant chiffrement, et un fichier choisi ne dépasse pas 10 Mo. La copie Android et les sauvegardes Kibuo doivent emporter le dossier `attachments/` avec la base. Une pièce retirée garde son fichier quelques secondes (« Annuler ») ; le ménage des fichiers orphelins viendra avec les sauvegardes.

« Ouvrir avec… » doit confier le fichier en clair à une autre appli : Kibuo en écrit une copie déchiffrée dans son cache (`shared/`), vidé à chaque nouvelle ouverture, si bien qu'une seule pièce au plus y reste en clair, hors des sauvegardes.
