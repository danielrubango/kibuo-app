# Données prêtes pour la synchronisation dès la V1

Chaque enregistrement porte dès le départ un identifiant UUID, une version en horloge logique, l'identifiant de l'appareil et une suppression logique, alors que la V1 n'a aucun code de synchronisation. Ajouter ces champs plus tard imposerait une migration lourde sur des données réelles.

Le journal détaillé des changements n'est pas créé en V1 : il arrive avec la synchronisation, et un premier envoi complet servira de point de départ.
