# Chapitre 3 : Guide de Développement Pas à Pas

> *"La théorie n'est rien sans la pratique. Pour construire un édifice robuste, chaque ligne de code doit être posée avec la précision d'une pierre de taille."*

---

## 3.1. Structure générale du projet

Pour assurer la maintenabilité de SECUR.IA, le projet utilise une architecture propre structurée par fonctionnalités (Feature-First) combinée à des couches de données (Data layers) bien isolées. 

Voici l'organisation des répertoires au sein du dossier `lib/` :

```
lib/
├── config/             # Paramètres globaux (couleurs, thèmes, config interactive)
├── core/               # Services centraux (bases de données, constantes, helpers)
├── models/             # Modèles de données (contacts, catégories)
├── screens/            # Écrans de l'application (auth, ia, annuaire, recherche)
├── widgets/            # Composants réutilisables (bulles de message, boutons)
├── wrappers/           # Logique d'aiguillage d'état (session de connexion)
├── app.dart            # Configuration de la racine de l'application
└── main.dart           # Point d'entrée de l'application
```

---

## 3.2. Initialisation et configuration globale (`main.dart`)

Le point d'entrée de l'application Flutter initialise les services Firebase, active la persistance locale de Firestore pour le mode déconnecté, et configure le fournisseur de thèmes globaux.

Voici le code source de [main.dart](file:///d:/Projets%20Informatiques/rescue/securia/lib/main.dart) :

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securia/wrappers/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:securia/app.dart';
import 'package:securia/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialisation de Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 2. Activation de la persistance hors-ligne de Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppConfig(),
      child: const MyApp(homePage: AuthWrapper()),
    ),
  );
}
```

---

## 3.3. Base de données locale : Implémentation de `DatabaseHelper`

Le fichier `database_helper.dart` gère la base de données SQLite locale de l'appareil. Elle stocke les tables de messages de chat, les pièces jointes associées (images, documents), et gère les migrations de schéma lors des mises à jour d'application.

Voici l'implémentation de la création des tables et de la gestion de version :

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pocam_chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Version incrémentée pour supporter les pièces jointes
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Création initiale de la base de données (SQLite)
  Future _createDB(Database db, int version) async {
    // Table des conversations de chat
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Table des messages de chat avec support multimédia
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        attachment_path TEXT,
        attachment_type TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');
  }

  // Gère la migration dynamique de schéma sans perte de données utilisateur
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajout des colonnes multimédias pour le support des photos et documents
      await db.execute("ALTER TABLE messages ADD COLUMN attachment_path TEXT;");
      await db.execute("ALTER TABLE messages ADD COLUMN attachment_type TEXT;");
    }
  }
}
```

---

## 3.4. Gestion des requêtes IA : Implémentation du moteur `ChatEngine`

Le `ChatEngine` est le cerveau de l'assistant Pocam237. Il prépare le payload JSON, injecte le prompt système institutionnel, gère l'historique conversationnel (pour donner une mémoire au chatbot) et encode en Base64 les pièces jointes multimédias pour l'API de Gemini.

Il récupère également la clé API Gemini de manière sécurisée et dynamique depuis Firestore :

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securia/core/version_helper.dart';

class ChatEngine {
  static const String _apiBaseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  static const String _systemPrompt = "Tu es Pocam237, un assistant juridique de la Police...";

  Future<String> sendMessage(
    String userPrompt, {
    List<Map<String, dynamic>> history = const [],
    String? attachmentPath,
    String? attachmentType,
  }) async {
    // 1. Récupération dynamique de la clé API Gemini depuis Firestore
    String apiKey = VersionHelper.geminiApiKey;
    if (apiKey.isEmpty) {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('version_control').get();
      if (doc.exists && doc.data() != null) {
        apiKey = doc.data()!['gemini_api_key'] ?? '';
        VersionHelper.geminiApiKey = apiKey;
      }
    }

    if (apiKey.isEmpty) return "Clé API Gemini introuvable.";

    final String apiUrl = "$_apiBaseUrl?key=$apiKey";
    final List<Map<String, dynamic>> contentsList = [];

    // 2. Traitement de l'historique de chat en mémoire
    // (Ajout des messages utilisateur et IA précédents)

    // 3. Encodage Base64 si une photo/image est jointe
    List<Map<String, dynamic>> currentParts = [{"text": userPrompt}];
    if (attachmentPath != null && attachmentType == 'image') {
      final bytes = await File(attachmentPath).readAsBytes();
      currentParts.add({
        "inlineData": {
          "mimeType": "image/jpeg",
          "data": base64Encode(bytes),
        }
      });
    }

    contentsList.add({"role": "user", "parts": currentParts});

    // 4. Appel HTTP POST vers les serveurs de Google
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "systemInstruction": {"parts": [{"text": _systemPrompt}]},
        "contents": contentsList,
        "generationConfig": {"temperature": 0.3, "maxOutputTokens": 8192}
      }),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['candidates'][0]['content']['parts'][0]['text'];
    }
    return "Erreur lors de l'appel à Pocam237.";
  }
}
```

---

## 3.5. Guide pour l'intégration UI Premium

Pour garantir une expérience premium, l'interface utilisateur de chat intègre des bulles de messages adaptées à la charte graphique, des indicateurs d'état de réseau animés, et un bouton d'attachement multimédia interactif.

### Vérification de l'état de réseau
L'application écoute le flux de connexion via `connectivity_plus` :
```dart
connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
  setState(() {
    isOffline = results.contains(ConnectivityResult.none);
  });
});
```

Si le téléphone est hors-ligne, un bandeau d'alerte couleur Or s'affiche en haut de l'écran avec une transition de hauteur (`AnimatedContainer`) pour avertir l'agent que l'IA est momentanément indisponible mais que l'annuaire reste 100% fonctionnel.
