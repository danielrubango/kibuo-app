# Versions publiées

Chaque version publiée a ici sa fiche : son numéro, son nom et sa note de publication en français et en anglais. L'agent les propose au propriétaire à chaque nouvelle version, avant de construire le paquet, et attend son « oui » (règle du 26 novembre 2026). Cela vaut aussi pour chaque nouveau paquet du test fermé : nom de version et note validés d'abord, paquet AAB construit ensuite (rappel du propriétaire, 26 novembre 2026).

## Les règles

- **Numéro** : `version` de `pubspec.yaml`, sous la forme `0.1.0+1`. La première partie (`0.1.0`) est celle que voient les utilisateurs, dans Google Play et dans À propos ; le nombre après `+` (code de version) monte de 1 à chaque paquet envoyé à Google Play, même pour un test, et ne redescend jamais. Pendant le test fermé, la version porte aussi `-alpha-` et le rang du paquet, visible dans À propos et en bas de Plus : `0.1.0-alpha-2+2` (propriétaire, 26 novembre 2026) ; `appVersion` dans `lib/app_version.dart` suit, et un test le vérifie.
- **Nom** dans la Play Console : `v` suivi du numéro, par exemple `v0.1.0` (choix du propriétaire, 26 novembre 2026). Google Play ne le montre qu'à nous. **Pendant le test fermé**, chaque paquet porte en plus `-alpha-` et son rang : `v0.1.0-alpha-1`, `v0.1.0-alpha-2`… (propriétaire, 26 novembre 2026) ; le rang suit le code de version du paquet. La version publique reprend `v0.1.0`.
- **Note de publication** (« Nouveautés » dans Google Play) : 500 caractères au plus par langue, proposée prête à coller, dans le bloc de la Play Console (`<fr-FR>` … `</fr-FR>`, puis `<en-US>` … `</en-US>`). Dite à l'utilisateur, en « vous », ce qu'il peut faire de nouveau, sans détail technique. Elle finit par l'adresse de contact.

## Avant chaque paquet

1. Construire la version de publication : `flutter build apk --release` (signée avec la clé d'importation, compactée par R8 comme le paquet de Google Play).
2. L'installer sur l'émulateur `Kibuo_Release` (Android 17, sans les données d'essai), l'ouvrir, faire le premier lancement et enregistrer une opération avec rappel, en lisant `adb logcat` : aucune « FATAL EXCEPTION ».
3. Seulement ensuite, `flutter build appbundle --release`.

Les versions d'essai (`--profile`) ne sont pas compactées : elles ne montrent pas ce genre de problème. Le 26 novembre 2026, les paquets `v0.1.0-alpha-1` et `-alpha-2` s'arrêtaient au lancement sur tous les téléphones, à cause de R8 (voir STATE, Pièges).

## Fiches

- [v0.1.0](0.1.0.md) : nom et note validés le 26 novembre 2026.
