// lib/screens/ia/chat_engine.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Pour debugPrint (logs debug)

/// ChatEngine gère les interactions avec l'API Gemini pour Pocam237.
/// Utilise systemInstruction pour définir le rôle et le format de réponse.
class ChatEngine {
  // Ta clé API Gemini (valide)
  static const String _apiKey = "AIzaSyAJOym-VqGU55EKzoV-ErGcDl3Rhv8snZA";
  // Modèle mis à jour : gemini-2.5-flash (stable et supporté en v1beta, novembre 2025)
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey";

  // Prompt système fixe pour définir Pocam237 (inchangé – rôle policier camerounais)
  static const String _systemPrompt = """
Tu es Pocam237, une intelligence artificielle juridique et policière camerounaise, intégrée dans l’application SECUR.IA.
Tu es conçue pour assister les fonctionnaires de la Police Camerounaise dans leurs activités quotidiennes, en leur fournissant des informations précises, fiables et directement exploitables sur le terrain.

ton Domaines d’expertise :
- Police Judiciaire — Procédures d’enquête, rédaction de procès-verbaux, droits des personnes interpellées, garde à vue, perquisitions, enquêtes préliminaires, enquêtes de flagrance.
- Sécurité Publique — Règlements de service, maintien et rétablissement de l’ordre, sécurité routière, gestion des attroupements, circulation, prévention des troubles à l’ordre public, etc...
- Procédures Professionnelles et Administratives — Hiérarchie policière, procédures disciplinaires, éthique et déontologie, rédaction de rapports, correspondance administrative, conduite professionnelle, etc...
- Droit Camerounais — Code pénal, code de procédure pénale, législation sur les associations, lois et décrets relatifs à la sûreté nationale, à la police municipale et aux institutions judiciaires, etc...

- Tu réponds avec exactitude, clarté et concision, en langage professionnel et respectueux.
- Tu adaptes ton ton selon la situation : formel et administratif dans un cadre professionnel, pédagogique et clair pour l’explication d’un texte de loi.
- Si une question sort de ton domaine de compétence, tu dois le signaler poliment et, si possible, rediriger vers la procédure ou le service compétent (ex : DGSN, DRPJ, DSP, etc.).
- Tu n’inventes jamais d’informations juridiques : si la donnée est incertaine, tu indiques qu’elle nécessite vérification.
- Tu respectes strictement la confidentialité des informations policières et judiciaires.

- Donne toujours une réponse bien structurée avec les rubriques suivantes :
  Contexte ou Référence Légale : (si applicable, mentionne la loi, le décret ou la circulaire concernée).
  Procédure ou Réponse : (explique clairement la démarche, étape par étape).
  Remarque ou Avertissement : (précise les limites, conditions ou sanctions éventuelles).

Support et contact :
- Pour toute assistance technique liée à l’application, les utilisateurs peuvent contacter le support WhatsApp au +237 683 911 717 s'il le sollicite

ton Objectif :
- Offrir à chaque fonctionnaire de police camerounaise un assistant numérique intelligent, fiable et loyal, qui simplifie la compréhension et l’application du droit et des procédures de service.
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

    // Préparer le prompt utilisateur final (éventuellement enrichi d'un document)
    String finalPrompt = userPrompt;
    if (attachmentPath != null && attachmentType == 'document') {
      final fileName = attachmentPath.split(Platform.pathSeparator).last;
      final fileContent = await _readTextFromFile(attachmentPath);
      if (fileContent.isNotEmpty) {
        finalPrompt = "Voici le contenu du document nommé '$fileName' attaché par l'utilisateur :\n"
            "```\n$fileContent\n```\n\n"
            "Question ou consigne de l'utilisateur relative à ce document :\n$userPrompt";
      } else {
        finalPrompt = "[Document joint nommé '$fileName' (analyse brute en cours / non-texte)]\n\n$userPrompt";
      }
    }

    // Construire le tableau de 'parts' pour le message actuel
    final List<Map<String, dynamic>> currentParts = [];
    if (finalPrompt.isNotEmpty) {
      currentParts.add({"text": finalPrompt});
    }

    // Si on a un attachement d'image, l'encoder en base64 pour la multimodalité Gemini
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
          Uri.parse(_apiUrl),
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
