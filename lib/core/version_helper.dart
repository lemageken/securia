// lib/core/version_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// VersionHelper gère la vérification des mises à jour obligatoires à distance
/// via Firebase Firestore et redirige vers le téléchargement de l'APK.
class VersionHelper {
  // Version installée actuellement sur le téléphone du policier
  static const String currentVersion = "1.0.0";

  // Stockage en mémoire de la clé API Gemini récupérée dynamiquement
  static String geminiApiKey = "";

  /// Vérifie s'il existe une nouvelle version dans Firestore et affiche le dialogue obligatoire.
  static Future<void> checkVersion(BuildContext context) async {
    try {
      // 1. Récupérer le document dans Firebase Firestore (app_config/version_control)
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_control')
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final String latestVersion = data['current_version'] ?? currentVersion;
      final String apkUrl = data['apk_url'] ?? '';
      
      // Récupérer et stocker la clé API Gemini
      geminiApiKey = data['gemini_api_key'] ?? '';

      // 2. Comparer la version actuelle et la dernière version
      if (_isVersionNewer(currentVersion, latestVersion) && apkUrl.isNotEmpty) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, apkUrl);
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification de version : $e");
    }
  }

  /// Compare deux versions au format 'x.y.z'. Retourne vrai si 'latest' est plus récent que 'current'.
  static bool _isVersionNewer(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
    } catch (e) {
      debugPrint("Erreur lors du parsing de version : $e");
    }
    return false;
  }

  /// Affiche la boîte de dialogue de mise à jour obligatoire (non fermable)
  static void _showUpdateDialog(BuildContext context, String latestVersion, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Empêche l'utilisateur de fermer en cliquant à côté
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Empêche le retour en arrière physique (Android)
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(
                  Icons.system_update_alt_rounded,
                  color: Color(0xFFD97706), // Accent Or
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  "Mise à jour obligatoire",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF152A56), // Couleur primaire sombre SecurIA
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Une nouvelle version ($latestVersion) de l'application SECUR.IA est disponible.",
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Veuillez la télécharger pour continuer à accéder à l'annuaire de police et à l'assistant IA Pocam237.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706), // Couleur Or
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 3,
                ),
                onPressed: () async {
                  final uri = Uri.parse(apkUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      throw "Impossible d'ouvrir le lien de téléchargement.";
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erreur : $e"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  "TÉLÉCHARGER LA MISE À JOUR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
