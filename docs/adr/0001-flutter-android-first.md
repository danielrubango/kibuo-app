# Flutter, lancement sur Android

L'application est écrite en Flutter et lancée d'abord sur Android, avec la logique métier en Dart pur séparée de l'interface. Le propriétaire ne maîtrise aucun langage mobile et le code est écrit par des agents : une seule base de code à tester réduit le risque, surtout pour les calculs d'argent et la future synchronisation.

Swift + Kotlin dupliquerait tout, et Kotlin Multiplatform dupliquerait les écrans. Le passage au natif n'aurait de toute façon pas permis un serveur web en arrière-plan sur iPhone : la contrainte vient d'iOS.
