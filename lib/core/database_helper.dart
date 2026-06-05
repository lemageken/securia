// lib/core/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseHelper est un singleton gérant la base de données SQLite locale pour SECUR.IA.
/// Il stocke l'historique des discussions avec l'IA (Pocam237) organisées en sessions de conversation.
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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // Activer le support des clés étrangères pour assurer le ON DELETE CASCADE
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE messages ADD COLUMN attachment_path TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN attachment_type TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    // Table des conversations (fils de discussion)
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Table des messages associés à chaque conversation avec support des pièces jointes
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL, -- 1 pour utilisateur, 0 pour Pocam237
        timestamp TEXT NOT NULL,
        attachment_path TEXT,
        attachment_type TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CRUD Conversations ---

  /// Récupère toutes les conversations locales triées par la plus récente.
  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;
    return await db.query('conversations', orderBy: 'created_at DESC');
  }

  /// Crée une nouvelle conversation et retourne son ID autoincrémenté.
  Future<int> createConversation(String title) async {
    final db = await database;
    return await db.insert('conversations', {
      'title': title,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Met à jour le titre d'une conversation.
  Future<int> updateConversationTitle(int id, String newTitle) async {
    final db = await database;
    return await db.update(
      'conversations',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Supprime une conversation (et tous ses messages associés grâce à ON DELETE CASCADE).
  Future<int> deleteConversation(int id) async {
    final db = await database;
    return await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Messages ---

  /// Récupère tous les messages d'une conversation donnée, triés chronologiquement.
  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Insère un nouveau message dans une conversation donnée avec support facultatif de pièce jointe.
  Future<int> insertMessage(
    int conversationId,
    String text,
    bool isUser, {
    String? attachmentPath,
    String? attachmentType,
  }) async {
    final db = await database;
    return await db.insert('messages', {
      'conversation_id': conversationId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
      'attachment_path': attachmentPath,
      'attachment_type': attachmentType,
    });
  }
  
  /// Vide complètement l'historique de la base de données (Utile pour réinitialisation complète).
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('conversations');
  }
}
