# Une devise par compte et des taux figés

Chaque compte a une seule devise, et toute conversion enregistre son taux sur l'opération. L'historique reste ainsi stable quand les taux changent, tandis que les rapports peuvent reconvertir à une date choisie. Les taux sont saisis par l'utilisateur, car l'application est offline.

Les montants sont stockés en entiers dans la plus petite unité de chaque devise, pour éviter les erreurs d'arrondi.

Mis en place le 15 novembre 2026 : un taux est un nombre décimal exact (« 655.957 »), conservé tel que saisi ; les conversions se calculent en entiers sans débordement et s'arrondissent à la moitié vers le haut. Chaque nouveau taux est une ligne de plus, jamais une modification, ce qui garde l'historique. La liste des devises vient des données Unicode CLDR (noms français et anglais, devise de chaque pays).
