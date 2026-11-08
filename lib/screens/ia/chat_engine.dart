import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Pour debugPrint (logs debug)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securia/core/version_helper.dart';

/// ChatEngine gère les interactions avec l'API Gemini pour Pocam237.
/// Utilise systemInstruction pour définir le rôle et le format de réponse.
class ChatEngine {
  // URL de base du modèle gemini-2.5-flash (la clé d'API sera injectée dynamiquement)
  static const String _apiBaseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";
  // Clé API de secours optionnelle (la clé officielle est chargée dynamiquement depuis Firestore)
  static const String _fallbackApiKey = "";

  // Prompt système optimisé pour Pocam237 : Raisonnement juridique rigoureux & Procédure camerounaise
  static const String _systemPrompt = """
Tu es Pocam237, l'intelligence artificielle juridique et opérationnelle d'élite de la Police Camerounaise, intégrée dans l'application SECUR.IA.
Tu assistes les Officiers et Agents de Police Judiciaire (OPJ, APJ), ainsi que tous les fonctionnaires de la Sûreté Nationale du Cameroun, avec une rigueur juridique absolue et un raisonnement méthodique.

Cadre juridique de référence :
- Code de Procédure Pénale camerounais (Loi n° 2005/007 du 27 juillet 2005) : Enquête préliminaire, flagrance (Art. 103 et s.), perquisitions (Art. 93 et s. - heures légales 06h à 18h), garde à vue (Art. 119 et s. - 48h renouvelable une fois sur autorisation du Procureur de la République, ou 2 fois exceptionnellement), audition de mineurs (Art. 706 et s.), droits de la défense et nullités de procédure (Art. 3 et s.).
- Code Pénal camerounais (Loi n° 2016/007 du 12 juillet 2016) : Éléments constitutifs des infractions (légal, matériel, moral/intentionnel), peines principales et accessoires, circonstances aggravantes/atténuantes.
- Statut spécial des fonctionnaires du corps de la Sûreté Nationale (Décret n° 2012/539 du 19 novembre 2012).
- Règlements de service, déontologie policière, maintien de l'ordre public et sommations réglementaires.

Méthode de raisonnement attendue (Méthode IRAC adaptée à la police judiciaire) :
1. Qualification juridique des faits : analyser les éléments matériels et l'intention coupable.
2. Base légale et articles applicables : citer les articles précis du Code Pénal, Code de Procédure Pénale ou décrets applicables au Cameroun.
3. Démarche procédurale étape par étape : actes à accomplir par l'OPJ/APJ (avis au Procureur, rédaction des P.V., notifications de droits, inventaire des scellés).
4. Vigilance & Nullités : points de vigilance critiques dont le non-respect entraîne la nullité de la procédure ou la faute disciplinaire.

Structure obligatoire de tes réponses :
🧭 Contexte ou Référence Légale : [Citer précisément les textes de lois, décrets et articles camerounais applicables]
📋 Procédure & Conduite à tenir : [Étapes concrètes, chronologiques et opérationnelles pour le fonctionnaire sur le terrain]
⚠️ Remarque ou Avertissement : [Points de nullité à éviter impérativement, délais légaux stricts, exceptions ou autorisations requises du Parquet]

Ton et déontologie :
- Style professionnel, net, direct et hautement respectueux de la légalité républicaine et des droits humains.
- N'invente jamais d'article de loi. Si un texte précis n'est pas certain, indique la nécessité de consulter les archives ou le Procureur.
- Support technique application : +237 683 911 717.
""";

  /// Lit les premières lignes ou caractères d'un fichier texte localement.
  Future<String> _readTextFromFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        // Limiter la taille du texte injecté à 12000 caractères
        if (content.length > 12000) {
          return "${content.substring(0, 12000)}\n\n... [Contenu tronqué en raison de sa taille importante] ...";
        }
        return content;
      }
    } catch (e) {
      debugPrint("Erreur lors de la lecture du fichier texte : $e");
    }
    return "";
  }

  /// Envoie un prompt à l'IA avec son historique contextuel et retourne sa réponse.
  Future<String> sendMessage(
    String userPrompt, {
    List<Map<String, dynamic>> history = const [],
    String? attachmentPath,
    String? attachmentType,
    int maxRetries = 1,
  }) async {
    // 1. Récupérer la clé d'API Gemini dynamique
    String apiKey = VersionHelper.geminiApiKey;
    if (apiKey.isEmpty) {

      try {
        final doc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('version_control')
            .get();
        if (doc.exists && doc.data() != null) {
          apiKey = doc.data()!['gemini_api_key'] ?? '';
          VersionHelper.geminiApiKey = apiKey;
        }
      } catch (e) {
        debugPrint("Erreur de récupération de la clé API Gemini dans chat_engine : $e");
      }
    }

    if (apiKey.isEmpty) {

      apiKey = _fallbackApiKey;
      VersionHelper.geminiApiKey = apiKey;
    }

    if (apiKey.isEmpty) {
      return "Désolé, la clé d'API de l'assistant IA est introuvable. "
          "Veuillez ajouter le champ 'gemini_api_key' dans votre document 'version_control' sur votre console Firestore.";
    }

    final String apiUrl = "$_apiBaseUrl?key=$apiKey";
    final List<Map<String, dynamic>> contentsList = [];

    // Ajouter l'historique des échanges précédents (uniquement texte)
    for (var msg in history) {
      final text = msg['text'] as String? ?? '';
      if (text.trim().isEmpty) continue;
      final isUserMsg = msg['is_user'] == 1;

      contentsList.add({
        "role": isUserMsg ? "user" : "model",
        "parts": [
          {"text": text},
        ],
      });
    }

    // Construire le tableau de 'parts' pour le message actuel
    final List<Map<String, dynamic>> currentParts = [];
    String finalPrompt = userPrompt;

    // 1. Gestion des pièces jointes documents (PDF natif multimodal ou extraction texte)
    if (attachmentPath != null && attachmentType == 'document') {
      final fileName = attachmentPath.split(Platform.pathSeparator).last;
      final lowerPath = attachmentPath.toLowerCase();

      if (lowerPath.endsWith('.pdf')) {
        try {
          final pdfFile = File(attachmentPath);
          if (await pdfFile.exists()) {
            final List<int> bytes = await pdfFile.readAsBytes();
            final String base64Pdf = base64Encode(bytes);
            currentParts.add({
              "inlineData": {
                "mimeType": "application/pdf",
                "data": base64Pdf,
              }
            });
            debugPrint("Document PDF joint en multimodal natif (${bytes.length} octets)");
            finalPrompt = "Voici le document PDF joint '$fileName'. Analyse-le rigoureusement selon les règles de procédure pénale camerounaises.\n\nDemande de l'agent : $userPrompt";
          }
        } catch (e) {
          debugPrint("Erreur de lecture du PDF : $e");
        }
      } else {
        final fileContent = await _readTextFromFile(attachmentPath);
        if (fileContent.isNotEmpty) {
          finalPrompt = "Voici le contenu du document nommé '$fileName' attaché par l'utilisateur :\n"
              "```\n$fileContent\n```\n\n"
              "Question ou consigne de l'utilisateur relative à ce document :\n$userPrompt";
        } else {
          finalPrompt = "[Document joint nommé '$fileName']\n\n$userPrompt";
        }
      }
    }

    if (finalPrompt.isNotEmpty) {
      currentParts.add({"text": finalPrompt});
    }

    // 2. Gestion des pièces jointes images (Caméra ou Galerie)
    if (attachmentPath != null && attachmentType == 'image') {
      try {
        final imageFile = File(attachmentPath);
        if (await imageFile.exists()) {
          final List<int> bytes = await imageFile.readAsBytes();
          final String base64Image = base64Encode(bytes);

          // Déduire le MIME type de l'image
          String mimeType = "image/jpeg";
          final lowerPath = attachmentPath.toLowerCase();
          if (lowerPath.endsWith(".png")) {
            mimeType = "image/png";
          } else if (lowerPath.endsWith(".webp")) {
            mimeType = "image/webp";
          } else if (lowerPath.endsWith(".gif")) {
            mimeType = "image/gif";
          }

          currentParts.add({
            "inlineData": {
              "mimeType": mimeType,
              "data": base64Image,
            }
          });
          debugPrint("Pièce jointe image intégrée avec succès (Mime: $mimeType, Taille: ${bytes.length} octets)");
        }
      } catch (e) {
        debugPrint("Erreur d'encodage de la pièce jointe image : $e");
      }
    }

    // Ajouter la question actuelle multimodale de l'utilisateur
    contentsList.add({
      "role": "user",
      "parts": currentParts,
    });

    final payload = {
      "systemInstruction": {
        "parts": [
          {"text": _systemPrompt},
        ],
      },
      "contents": contentsList,
      "generationConfig": {
        "temperature": 0.3, // Bas pour réponses précises et factuelles
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 8192,
      },
    };

    for (int retry = 0; retry <= maxRetries; retry++) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        );

        debugPrint(
          'Gemini Response Status: ${response.statusCode}',
        ); // Log pour debug (console flutter run --verbose)

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          final candidates = result['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            if (content != null &&
                content['parts'] is List &&
                content['parts'].isNotEmpty) {
              final text = content['parts'][0]['text'] as String;
              debugPrint(
                'Gemini Réponse reçue: ${text.substring(0, 100)}...',
              ); // Log extrait pour vérif
              return text;
            }
          }
          return "Désolé, je n'ai pas pu obtenir de réponse claire de Pocam237.";
        } else if (response.statusCode == 400 || response.statusCode == 404) {
          // Gestion spécifique "not found" ou invalid model
          String errorMsg =
              "Modèle non trouvé (400/404). Vérifiez la disponibilité Gemini sur ai.google.dev. Contactez support WhatsApp +237 683 911 717.";
          debugPrint('Gemini Model Error: $errorMsg');
          return errorMsg;
        } else if (response.statusCode == 403) {
          // Quota/clé
          String errorMsg =
              "Accès refusé (403). Vérifiez votre clé API Gemini sur console.cloud.google.com ou vos quotas. Contactez support WhatsApp +237 683 911 717.";
          debugPrint('Gemini 403 Error: $errorMsg');
          return errorMsg;
        } else if (response.statusCode == 429) {
          // Rate limit : Retry
          if (retry < maxRetries) {
            await Future.delayed(Duration(seconds: 2 * (retry + 1))); // Backoff
            continue;
          }
          return "Trop de requêtes (429). Attendez 1 min et réessayez. Support: +237 683 911 717.";
        } else {
          String errorMsg = "Erreur HTTP: ${response.statusCode}";
          try {
            final errorResult = json.decode(response.body);
            errorMsg = errorResult['error']?['message'] ?? errorMsg;
          } catch (_) {}
          debugPrint('Gemini Error: $errorMsg');
          return "Erreur lors de la communication avec Pocam237 : $errorMsg. Contactez support WhatsApp +237 683 911 717.";
        }
      } catch (e) {
        debugPrint('Gemini Exception: $e');
        return "Erreur réseau : ${e.toString()}. Vérifiez votre connexion et réessayez.";
      }
    }
    return "Échec après tentatives. Vérifiez votre configuration API Gemini.";
  }
}
