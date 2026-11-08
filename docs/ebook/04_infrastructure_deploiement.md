# Chapitre 4 : Infrastructure, Déploiement & Sécurité

> *"Le code le plus performant n'est rien s'il est exposé aux failles. Déployer une application, c'est ériger un rempart de sécurité autour de l'information."*

---

## 4.1. Configuration pas à pas de Firebase

Pour déployer SECUR.IA avec votre nouveau compte Firebase (par exemple, suite à votre transition vers le compte `simomel3@gmail.com`), voici la marche à suivre :

### A. Configuration de l'authentification (Authentication)
1. Allez sur votre [Console Firebase](https://console.firebase.google.com/).
2. Dans le volet de gauche, cliquez sur **Build > Authentication**.
3. Cliquez sur **Get Started** (Commencer).
4. Sous l'onglet **Sign-in method**, activez le fournisseur **Email/Password** (Adresse e-mail/Mot de passe).
5. Dans l'onglet **Templates**, personnalisez les e-mails de réinitialisation de mot de passe avec le nom de marque de l'application (ex : "SECUR.IA - Réinitialisation de votre accès").

### B. Création de la base Firestore
1. Allez dans **Build > Firestore Database** et cliquez sur **Create database**.
2. Choisissez la localisation de serveur la plus proche de votre zone cible pour minimiser la latence (par exemple `europe-west3` pour l'Afrique de l'Ouest/Centrale).
3. Sélectionnez le mode de démarrage (Start in test mode) pour le développement.

---

## 4.2. Règles de sécurité Firestore de production

Il est crucial d'interdire l'accès public non authentifié à vos données. Voici les règles de sécurité prêtes pour la production à copier-coller dans l'onglet **Rules** de votre base Firestore :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 1. Autoriser la lecture publique de la configuration de version et de la clé API
    // (Nécessaire au démarrage de l'app avant même que l'utilisateur soit connecté)
    match /app_config/version_control {
      allow read: if true;
      allow write: if false; // Seul l'administrateur peut écrire depuis la console
    }
    
    // 2. Règles pour les profils et données privées des agents
    // (Nécessite impérativement une authentification Firebase valide)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 4.3. Gestion de la politique de mise à jour obligatoire à distance

Pour éviter que des utilisateurs n'utilisent des versions obsolètes de l'annuaire (ce qui poserait des problèmes opérationnels majeurs), SECUR.IA intègre un service de vérification obligatoire au démarrage : `VersionHelper`.

Voici l'implémentation de la vérification de version à distance :

```dart
// lib/core/version_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionHelper {
  static const String currentVersion = "1.0.0";
  static String geminiApiKey = "";

  static Future<void> checkVersion(BuildContext context) async {
    try {
      // 1. Récupération des informations sur Firestore
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_control')
          .get();

      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      final String latestVersion = data['current_version'] ?? currentVersion;
      final String apkUrl = data['apk_url'] ?? '';
      
      // Récupération dynamique de la clé API pour éviter l'exposition de secrets
      geminiApiKey = data['gemini_api_key'] ?? '';

      // 2. Blocage si la version est plus ancienne
      if (_isVersionNewer(currentVersion, latestVersion) && apkUrl.isNotEmpty) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, apkUrl);
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification de version : $e");
    }
  }

  static bool _isVersionNewer(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      int latestPart = i < latestParts.length ? latestParts[i] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  // Pop-up persistant et obligatoire de mise à jour
  static void _showUpdateDialog(BuildContext context, String latestVersion, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Empêche l'utilisateur de fermer en cliquant à côté
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Empêche le retour physique Android
          child: AlertDialog(
            title: const Text("Mise à jour obligatoire"),
            content: Text("Une nouvelle version ($latestVersion) de SECUR.IA est disponible. Veuillez l'installer pour continuer."),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(apkUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text("TÉLÉCHARGER LA MISE À JOUR"),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 4.4. Distribution d'APK via GitHub Releases (Alternative gratuite à Storage)

Pour distribuer l'application sans payer d'hébergement Firebase Storage et sans avoir à fournir de carte bancaire, la meilleure pratique consiste à utiliser les **Releases** de votre dépôt GitHub.

```
[Flutter Build (PC)] 
       |
       v (apk)
[GitHub Releases (Serveur public gratuit)] 
       |
       v (copie du lien direct de l'APK)
[Firestore app_config/version_control]
       |
       v (comparaison au lancement)
[Smartphone de l'agent] ---> Lance le téléchargement direct de l'APK GitHub
```

### Avantages de cette méthode :
*   **100% Gratuit** : Pas de frais de bande passante sur les téléchargements de fichiers lourds (comme l'APK qui pèse entre 15 et 30 Mo).
*   **Résilience** : Les serveurs de téléchargement de GitHub disposent d'un taux de disponibilité exceptionnel (CDN mondial).
*   **Simplicité de mise à jour** : Il suffit de téléverser l'APK généré lors du build sur une nouvelle release GitHub, d'obtenir le lien de téléchargement direct de l'APK, et de le reporter dans le document Firestore `version_control` (champ `apk_url`).
