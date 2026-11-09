import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Pour debugPrint (logs debug)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securia/core/version_helper.dart';

/// ChatEngine gère les interactions avec l'API Gemini pour Pocam237.
/// Utilise systemInstruction pour définir le rôle et le format de réponse.
/// Intègre un mécanisme de résilience multi-modèle (cascade fallback) en cas de forte affluence.
class ChatEngine {
  // Modèles par défaut (actualisables dynamiquement via Firestore 'app_config/version_control')
  static const String _defaultPrimaryModel = "gemini-2.5-flash";
  static const String _defaultFallbackModel = "gemini-3.1-flash-lite";

  // Clé API de secours optionnelle (la clé officielle est chargée dynamiquement depuis Firestore)
  static const String _fallbackApiKey = "";

  // URL générique vers l'API Gemini
  static String _getModelUrl(String modelName, String apiKey) {
    return "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey";
  }

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
  /// En cas de forte demande ou d'erreur transitoire sur le modèle principal,
  /// bascule automatiquement de façon transparente sur le modèle de secours.
  Future<String> sendMessage(
    String userPrompt, {
    List<Map<String, dynamic>> history = const [],
    String? attachmentPath,
    String? attachmentType,
    int maxRetries = 1,
  }) async {
    // 1. Récupérer la clé d'API Gemini dynamique et les modèles configurés
    String apiKey = VersionHelper.geminiApiKey;
    String primaryModel = VersionHelper.geminiModel.isNotEmpty
        ? VersionHelper.geminiModel
        : _defaultPrimaryModel;
    String fallbackModel = VersionHelper.geminiFallbackModel.isNotEmpty
        ? VersionHelper.geminiFallbackModel
        : _defaultFallbackModel;

    if (apiKey.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('version_control')
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          apiKey = data['gemini_api_key'] ?? '';
          if (apiKey.isNotEmpty) {
            VersionHelper.geminiApiKey = apiKey;
          }
          if ((data['gemini_model'] ?? '').toString().isNotEmpty) {
            primaryModel = data['gemini_model'];
            VersionHelper.geminiModel = primaryModel;
          }
          if ((data['gemini_fallback_model'] ?? '').toString().isNotEmpty) {
            fallbackModel = data['gemini_fallback_model'];
            VersionHelper.geminiFallbackModel = fallbackModel;
          }
        }
      } catch (e) {
        debugPrint("Erreur de récupération de la configuration Gemini : $e");
      }
    }

    if (apiKey.isEmpty) {
      apiKey = _fallbackApiKey;
      VersionHelper.geminiApiKey = apiKey;
    }

    if (apiKey.isEmpty) {
      return "Désolé, la clé d'API de l'assistant IA est introuvable. "
          "Veuillez vérifier le champ 'gemini_api_key' dans Firestore 'version_control'.";
    }

    // 2. Préparer l'historique de conversation
    final List<Map<String, dynamic>> contentsList = [];
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

    // 3. Préparer les 'parts' pour le message actuel (texte + multimodal)
    final List<Map<String, dynamic>> currentParts = [];
    String finalPrompt = userPrompt;

    // A. Pièce jointe document (PDF natif multimodal ou extraction texte)
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

    // B. Pièce jointe image (Caméra ou Galerie)
    if (attachmentPath != null && attachmentType == 'image') {
      try {
        final imageFile = File(attachmentPath);
        if (await imageFile.exists()) {
          final List<int> bytes = await imageFile.readAsBytes();
          final String base64Image = base64Encode(bytes);

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
          debugPrint("Pièce jointe image intégrée avec succès ($mimeType, ${bytes.length} octets)");
        }
      } catch (e) {
        debugPrint("Erreur d'encodage de la pièce jointe image : $e");
      }
    }

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
        "temperature": 0.3, // Bas pour des réponses procédurales précises et fiables
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 8192,
      },
    };

    // 4. Cascade de modèles avec détection de surchauffe (High Demand / 503 / 429)
    final List<String> modelsToTry = [
      primaryModel,
      if (fallbackModel != primaryModel) fallbackModel,
    ];

    for (int modelIdx = 0; modelIdx < modelsToTry.length; modelIdx++) {
      final currentModel = modelsToTry[modelIdx];
      final bool hasNextModel = (modelIdx + 1) < modelsToTry.length;
      final String apiUrl = _getModelUrl(currentModel, apiKey);

      debugPrint("Tentative d'interrogation Gemini avec le modèle : $currentModel");

      for (int retry = 0; retry <= maxRetries; retry++) {
        try {
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          ).timeout(const Duration(seconds: 25));

          debugPrint('Gemini [$currentModel] Response Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final result = json.decode(response.body);
            final candidates = result['candidates'];
            if (candidates is List && candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              if (content != null &&
                  content['parts'] is List &&
                  content['parts'].isNotEmpty) {
                final text = content['parts'][0]['text'] as String;
                debugPrint('Gemini [$currentModel] Réponse reçue avec succès (${text.length} caractères)');
                return text;
              }
            }
            if (hasNextModel) {
              debugPrint("Réponse 200 sans candidat exploitable, essai du modèle alternatif...");
              break;
            }
            return "Désolé, je n'ai pas pu obtenir de réponse claire de Pocam237.";
          }

          // Analyser le contenu de l'erreur pour détecter une saturation
          String errorBody = "";
          try {
            final errorJson = json.decode(response.body);
            errorBody = errorJson['error']?['message'] ?? response.body;
          } catch (_) {
            errorBody = response.body;
          }

          final lowerError = errorBody.toLowerCase();
          final bool isCapacityOverload = response.statusCode == 503 ||
              response.statusCode == 429 ||
              lowerError.contains("high demand") ||
              lowerError.contains("spikes in demand") ||
              lowerError.contains("overloaded") ||
              lowerError.contains("resource_exhausted") ||
              lowerError.contains("capacity");

          if (isCapacityOverload) {
            debugPrint("Surcharge détectée sur [$currentModel] : $errorBody");
            if (hasNextModel) {
              debugPrint("BASCULEMENT IMMÉDIAT vers le modèle de repli : ${modelsToTry[modelIdx + 1]}");
              break; // Passer directement au modèle de secours
            }
            if (retry < maxRetries) {
              await Future.delayed(Duration(seconds: 2 * (retry + 1)));
              continue;
            }
          }

          if (response.statusCode == 400 || response.statusCode == 404) {
            debugPrint("Modèle [$currentModel] non disponible (HTTP ${response.statusCode})");
            if (hasNextModel) {
              break; // Essayer le fallback
            }
          }

          if (response.statusCode == 403) {
            debugPrint("Accès refusé (403) sur la clé API : $errorBody");
            return "Accès refusé (403). Vérifiez votre clé API Gemini sur la console Google. Support WhatsApp : +237 683 911 717.";
          }

          // Si autre code erreur HTTP non récupérable, passer au modèle suivant si existant
          if (hasNextModel) {
            break;
          }

        } catch (e) {
          debugPrint("Gemini [$currentModel] Exception (tentative ${retry + 1}) : $e");
          if (hasNextModel) {
            debugPrint("Exception réseau/timeout sur $currentModel, basculement vers modèle de repli...");
            break;
          }
          if (retry < maxRetries) {
            await Future.delayed(Duration(seconds: 2 * (retry + 1)));
            continue;
          }
        }
      }
    }

    return "⚠️ Pocam237 est momentanément indisponible en raison d'une forte demande réseau sur les serveurs d'intelligence artificielle. Veuillez reformuler votre question ou réessayer dans quelques instants.\n\nSupport technique : +237 683 911 717.";
  }
}
