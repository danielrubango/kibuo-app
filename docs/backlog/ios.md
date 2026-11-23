---
title: Portage sur iOS
milestone: iOS
labels: [plateforme]
---

# Portage sur iOS

Le code Flutter reste compilable pour iOS, mais iOS n'est ni testé ni publié avant la stabilisation d'Android.

## Registre des spécificités Android

À compléter dans le même changement que tout ajout dépendant d'Android.

| Fonction | Élément propre à Android | Équivalent iOS | État |
|---|---|---|---|
| Langue de l'application | Liste des langues dans « Langue de l'application » d'Android 13+ (`res/xml/locales_config.xml`) | Langues déclarées dans le projet iOS, pour le choix de langue par appli des Réglages | À faire |
| Empreinte | `local_auth` sur Android : activité `FlutterFragmentActivity`, thème AppCompat, permission `USE_BIOMETRIC` | Face ID et Touch ID, avec la mention d'usage `NSFaceIDUsageDescription` | À faire |
| Confidentialité | `FLAG_SECURE` contre les captures, `setRecentsScreenshotEnabled` (Android 13+) pour masquer l'aperçu, canal `kibuo/privacy` dans `MainActivity` | Écran de masquage à la sortie de l'appli (iOS ne bloque pas les captures) | À faire |
| Réclamer une créance | Menu de partage d'Android (`Intent.ACTION_SEND`, méthode `shareText` du canal `kibuo/device`) pour envoyer le message par SMS, WhatsApp… | Feuille de partage iOS (`UIActivityViewController`) avec le même texte | À faire |
| Copie des données | `KibuoBackupAgent` : copie par Android seulement avec un code de récupération et le réglage actif ; `data_extraction_rules.xml` et `backup_rules.xml` limitent la copie à `kibuo.db`, `kibuo-key.json` et au dossier chiffré `attachments/` | Sauvegarde iCloud et transfert d'iPhone limités aux mêmes fichiers, selon le même réglage ; le reste exclu (`isExcludedFromBackup`) | À faire |
| Coffre de la clé | `flutter_secure_storage` sur le Keystore d'Android | Trousseau iOS sans synchronisation iCloud (option d'accessibilité « cet appareil uniquement ») | À faire |
| Pays du téléphone | Canal `kibuo/device` : pays du réseau ou de la carte SIM (`TelephonyManager`), sinon des réglages du système | Pays de la région des Réglages (`Locale.current.region`) | À faire |
| Langue choisie au premier lancement | Canal `kibuo/device`, méthode `appLanguage` : `LocaleManager.setApplicationLocales` (Android 13+), sinon langue gardée par kibuo | Langue par appli des Réglages iOS (ouvrir les Réglages de l'appli), sinon langue gardée par kibuo | À faire |
| Pièces jointes : photo et galerie | `image_picker` (appareil photo, galerie, réduction à 1 600 px) | Mentions `NSCameraUsageDescription` et `NSPhotoLibraryUsageDescription` dans Info.plist | À faire |
| Pièces jointes : fichiers | `file_picker` (PDF et images) | Sélecteur de documents iOS ; vérifier les PDF venant d'iCloud Drive | À faire |
| Pièces jointes : première page d'un PDF | `pdfx` (PdfRenderer d'Android) | Vérifier le rendu PDFKit sur iOS | À faire |
| Pièces jointes : « Ouvrir avec… » | `open_filex` (FileProvider ; ses permissions de lecture du stockage sont retirées du manifeste) | Feuille de partage iOS (UIDocumentInteractionController) ; la copie en clair va dans le cache | À faire |
| Pièces jointes : copie Android | Dossier `attachments/` inclus dans la copie Android, chiffré (ADR 0011) | Exclure le dossier de la sauvegarde iCloud, comme la base | À faire |
| Écran de démarrage | Écran d'Android 12+ (`windowSplashScreenAnimatedIcon`) et fond de lancement d'Android 8 à 11 | Écran de lancement iOS (LaunchScreen) avec le même logo, centré à la même taille que l'écran Kibuo | À faire |

## Différences déjà connues

| Sujet | À prévoir sur iOS |
|---|---|
| Biométrie | Face ID et Touch ID, avec la mention d'usage requise |
| Stockage de la clé | Trousseau iOS, en excluant la synchronisation iCloud |
| Rappels | `flutter_local_notifications` (récepteurs Android, désucrage Java) : sur iOS, autorisation à demander via `DarwinInitializationSettings`, limite de 64 notifications programmées, à vérifier ; fuseau via `flutter_timezone` |
| Sauvegardes | Sélecteur de fichiers et dossier iCloud ou local |
| Serveur web local | Fonctionne uniquement application ouverte, comme accepté |
| Modèle d'IA système | iPhone 15 Pro ou plus récent, si l'IA embarquée est retenue |

## Étapes

1. Relire le registre et vérifier chaque dépendance sur iOS.
2. Compiler et lancer sur le simulateur.
3. Adapter les permissions et la mise en page.
4. Tester sauvegarde, restauration et transfert depuis Android.
5. Tester sur un iPhone réel, puis publier via TestFlight et l'App Store.
