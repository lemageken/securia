// lib/screens/ia/pocam_chat_page.dart

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:securia/core/app_colors.dart';
import 'package:securia/core/database_helper.dart';
import 'package:securia/screens/ia/chat_engine.dart';
import 'package:securia/screens/home/home_page.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? attachmentPath;
  final String? attachmentType;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.attachmentPath,
    this.attachmentType,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PocamChatPage extends StatefulWidget {
  const PocamChatPage({super.key});

  @override
  State<PocamChatPage> createState() => _PocamChatPageState();
}

class _PocamChatPageState extends State<PocamChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatEngine _engine = ChatEngine();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final List<Message> _messages = [];
  List<Map<String, dynamic>> _conversationsList = [];
  int? _currentConversationId;
  bool _isLoading = false;
  bool _isInitLoading = true;

  // Gestion des pièces jointes en cours
  String? _selectedAttachmentPath;
  String? _selectedAttachmentType;
  String? _selectedAttachmentName;

  // Gestion de la connectivité hors-ligne
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initChatSession();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialise la session de chat : charge l'historique ou crée une conversation par défaut.
  Future<void> _initChatSession() async {
    try {
      await _loadConversations();
      if (_conversationsList.isNotEmpty) {
        // Charger la discussion la plus récente
        final lastConvId = _conversationsList.first['id'] as int;
        await _selectConversation(lastConvId);
      } else {
        // Aucune discussion existante, en créer une nouvelle
        await _startNewConversation();
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    } finally {
      setState(() {
        _isInitLoading = false;
      });
    }
  }

  /// Charge toutes les sessions de conversation de la base de données.
  Future<void> _loadConversations() async {
    final list = await _dbHelper.getConversations();
    setState(() {
      _conversationsList = list;
    });
  }

  /// Sélectionne une conversation active et charge ses messages associés.
  Future<void> _selectConversation(int conversationId) async {
    setState(() {
      _currentConversationId = conversationId;
      _messages.clear();
      _isLoading = true;
    });

    try {
      final msgList = await _dbHelper.getMessages(conversationId);
      setState(() {
        _messages.addAll(msgList.map((m) => Message(
              text: m['text'] as String,
              isUser: m['is_user'] == 1,
              timestamp: DateTime.parse(m['timestamp'] as String),
              attachmentPath: m['attachment_path'] as String?,
              attachmentType: m['attachment_type'] as String?,
            )));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Crée un tout nouveau fil de discussion et bascule dessus.
  Future<void> _startNewConversation() async {
    try {
      final newId = await _dbHelper.createConversation("Nouvelle discussion");
      await _loadConversations();
      await _selectConversation(newId);
    } catch (e) {
      debugPrint('Error starting new conversation: $e');
    }
  }

  /// Supprime définitivement un fil de discussion.
  Future<void> _deleteConversation(int id) async {
    try {
      await _dbHelper.deleteConversation(id);
      await _loadConversations();

      // Si on a supprimé la conversation courante, charger la suivante ou en créer une neuve
      if (_currentConversationId == id) {
        if (_conversationsList.isNotEmpty) {
          final nextId = _conversationsList.first['id'] as int;
          await _selectConversation(nextId);
        } else {
          await _startNewConversation();
        }
      }
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Ouvre le menu modal pour attacher des images ou documents.
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Joindre un élément',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_rounded, color: Colors.blue),
                ),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image_rounded, color: Colors.green),
                ),
                title: const Text('Sélectionner depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.orange),
                ),
                title: const Text('Importer un document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Permet de sélectionner une image ou de prendre une photo.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Optimisation du poids pour l'API Gemini
      );
      if (image != null) {
        setState(() {
          _selectedAttachmentPath = image.path;
          _selectedAttachmentType = 'image';
          _selectedAttachmentName = image.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la capture/sélection : $e")),
        );
      }
    }
  }

  /// Permet de sélectionner un document de type texte ou bureautique.
  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv', 'md', 'json'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAttachmentPath = result.files.single.path;
          _selectedAttachmentType = 'document';
          _selectedAttachmentName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking document: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de sélection de document : $e")),
        );
      }
    }
  }

  /// Envoie le message saisi par l'utilisateur (avec support multimédia/pièces jointes).
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _selectedAttachmentPath == null) || _isLoading || _isOffline || _currentConversationId == null) {
      return;
    }

    final isFirstMessage = _messages.isEmpty;

    // Sauvegarder les données de pièce jointe en cours avant de réinitialiser l'état
    final String? attachmentPath = _selectedAttachmentPath;
    final String? attachmentType = _selectedAttachmentType;
    final String? attachmentName = _selectedAttachmentName;

    try {
      // 1. Sauvegarder le message de l'utilisateur dans la base locale
      await _dbHelper.insertMessage(
        _currentConversationId!,
        text,
        true,
        attachmentPath: attachmentPath,
        attachmentType: attachmentType,
      );

      // 2. Si c'est le tout premier message, renommer automatiquement la conversation
      if (isFirstMessage) {
        String newTitle = text.isNotEmpty
            ? text
            : (attachmentType == 'image' ? "Image jointe" : "Document joint : $attachmentName");
        final words = newTitle.split(' ');
        if (words.length > 5) {
          newTitle = "${words.take(5).join(' ')}...";
        } else if (newTitle.length > 25) {
          newTitle = "${newTitle.substring(0, 25)}...";
        }
        await _dbHelper.updateConversationTitle(_currentConversationId!, newTitle);
        await _loadConversations();
      }

      // Obtenir la copie de l'historique de discussion pour le contexte IA
      final historyList = _messages.map((m) => {
            'text': m.text,
            'is_user': m.isUser ? 1 : 0,
          }).toList();

      // 3. Mettre à jour l'interface
      setState(() {
        _messages.add(Message(
          text: text,
          isUser: true,
          attachmentPath: attachmentPath,
          attachmentType: attachmentType,
        ));
        _isLoading = true;
        _controller.clear();
        _selectedAttachmentPath = null;
        _selectedAttachmentType = null;
        _selectedAttachmentName = null;
      });
      _scrollToBottom();

      // 4. Envoyer la requête à l'API Gemini
      final response = await _engine.sendMessage(
        text,
        history: historyList,
        attachmentPath: attachmentPath,
        attachmentType: attachmentType,
      );

      // 5. Sauvegarder la réponse de Pocam237 dans la base locale
      await _dbHelper.insertMessage(_currentConversationId!, response, false);

      setState(() {
        _messages.add(Message(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Chat Error: $e');
      setState(() {
        _messages.add(Message(text: "Erreur réseau ou quota. Veuillez réessayer.", isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  /// Construit le rendu visuel d'une pièce jointe dans les bulles de discussion.
  Widget _buildMessageAttachment(Message message) {
    final String path = message.attachmentPath!;
    final String type = message.attachmentType!;
    final bool isUser = message.isUser;
    final String name = path.split(Platform.pathSeparator).last;

    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          width: double.infinity,
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(12),
                color: isUser ? Colors.blue.shade900.withAlpha((0.3 * 255).round()) : Colors.grey.shade200,
                child: Row(
                  children: [
                    const Icon(Icons.broken_image, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Image introuvable localement : $name",
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser ? Colors.white70 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Document
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser ? Colors.white.withAlpha((0.15 * 255).round()) : Colors.black.withAlpha((0.04 * 255).round()),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUser ? Colors.white.withAlpha((0.2 * 255).round()) : Colors.black.withAlpha((0.08 * 255).round()),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_rounded,
              color: isUser ? Colors.white : AppColors.primaryDark,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isUser ? Colors.white : AppColors.textColorPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Document',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : AppColors.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Formate et rend le texte de réponse du chatbot avec les titres/sous-titres en gras et sélectionnable.
  Widget _buildFormattedText(String text, TextStyle baseStyle) {
    final List<String> lines = text.split('\n');
    final List<TextSpan> lineSpans = [];

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String trimmedLine = line.trim();

      // Vérifie si la ligne est un titre/sous-titre
      bool isHeader = false;
      String cleanLine = line;

      if (trimmedLine.startsWith('### ')) {
        isHeader = true;
        cleanLine = line.replaceFirst('### ', '');
      } else if (trimmedLine.startsWith('## ')) {
        isHeader = true;
        cleanLine = line.replaceFirst('## ', '');
      } else if (trimmedLine.startsWith('# ')) {
        isHeader = true;
        cleanLine = line.replaceFirst('# ', '');
      } else {
        // Enlève le markdown ** temporairement pour détecter les rubriques
        final String trimmedClean = trimmedLine.replaceAll('**', '').trim();
        final String lower = trimmedClean.toLowerCase();

        if (lower.startsWith('contexte ou référence légale') ||
            lower.startsWith('procédure ou réponse') ||
            lower.startsWith('remarque ou avertissement') ||
            lower.startsWith('contexte') ||
            lower.startsWith('procédure') ||
            lower.startsWith('remarque') ||
            lower.startsWith('avertissement') ||
            (trimmedClean.endsWith(':') &&
                trimmedClean.length < 50 &&
                !trimmedClean.startsWith('http') &&
                !trimmedClean.contains('/'))) {
          isHeader = true;
          // Nettoie les marqueurs markdown puisqu'on va formater toute la ligne en gras
          cleanLine = line.replaceAll('**', '');
        }
      }

      // Ajoute un saut de ligne si ce n'est pas la première ligne
      if (i > 0) {
        lineSpans.add(TextSpan(text: '\n', style: baseStyle));
      }

      if (isHeader) {
        lineSpans.add(TextSpan(
          text: cleanLine,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! + 0.5 : 16.5,
          ),
        ));
      } else {
        // Formate le gras inline (ex: **texte en gras**)
        lineSpans.addAll(_parseInlineFormatting(line, baseStyle));
      }
    }

    return SelectableText.rich(
      TextSpan(children: lineSpans),
      style: baseStyle,
    );
  }

  /// Parse le gras inline standard (**texte**)
  List<TextSpan> _parseInlineFormatting(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return spans;
  }

  /// Construit la bulle de discussion standard.
  Widget _buildBubble(Message message) {
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? AppColors.userMessageColor : AppColors.iaMessageColor;
    final textColor = message.isUser ? AppColors.userMessageText : AppColors.iaMessageText;

    final bubbleContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rendu visuel de la pièce jointe s'il y en a une
          if (message.attachmentPath != null) ...[
            _buildMessageAttachment(message),
            const SizedBox(height: 8),
          ],
          if (message.text.isNotEmpty)
            message.isUser
                ? SelectableText(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 16),
                  )
                : _buildFormattedText(
                    message.text,
                    TextStyle(color: textColor, fontSize: 16),
                  ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  color: textColor.withAlpha((0.7 * 255).round()),
                  fontSize: 12,
                ),
              ),
              if (!message.isUser)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Réponse de Pocam237 copiée !'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.copy_rounded,
                      color: textColor.withAlpha((0.7 * 255).round()),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (message.isUser) {
      return Align(
        alignment: alignment,
        child: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message copié dans le presse-papiers')),
            );
          },
          child: bubbleContent,
        ),
      );
    } else {
      return Align(
        alignment: alignment,
        child: bubbleContent,
      );
    }
  }

  /// Construit le panneau d'aperçu d'attachement juste au-dessus du champ de texte.
  Widget _buildAttachmentPreview() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (_selectedAttachmentType == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedAttachmentPath!),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description, color: AppColors.primaryDark),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAttachmentName ?? 'Fichier joint',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textColorPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedAttachmentType == 'image' ? 'Image prête' : 'Document prêt',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _selectedAttachmentPath = null;
                _selectedAttachmentType = null;
                _selectedAttachmentName = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Chat avec Pocam237'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_rounded),
            tooltip: 'Annuaire des contacts',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainHomePage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.backgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Image.asset('assets/images/logo_police.jpg'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pocam237',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Assistant Police',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bouton Nouvelle Discussion
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // fermer le drawer
                  _startNewConversation();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nouvelle discussion',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.activeIconColorPink, // Accent Or Camerounais
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Liste des discussions enregistrées
            Expanded(
              child: _conversationsList.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune discussion enregistrée',
                        style: TextStyle(color: AppColors.textColorSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _conversationsList.length,
                      itemBuilder: (context, index) {
                        final conv = _conversationsList[index];
                        final id = conv['id'] as int;
                        final title = conv['title'] as String;
                        final isSelected = id == _currentConversationId;

                        return ListTile(
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: isSelected
                                ? AppColors.activeIconColorPink
                                : AppColors.inActiveIconColor,
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryDark : AppColors.textColorPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppColors.userMessageColor, // Fond bleu ciel doux
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Supprimer la discussion'),
                                  content: const Text(
                                    'Voulez-vous vraiment supprimer définitivement cette discussion et son historique ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteConversation(id);
                                      },
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context); // fermer le drawer
                            _selectConversation(id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bannière élégante et animée d'avertissement en mode hors-ligne
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isOffline ? 48.0 : 0.0,
                  curve: Curves.easeInOut,
                  color: AppColors.activeIconColorPink, // Or Camerounais
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 48.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Mode hors-ligne - Assistant indisponible. L'annuaire reste 100% fonctionnel.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: AppColors.inActiveIconColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Commencez votre discussion avec Pocam237...",
                                style: TextStyle(
                                  color: AppColors.textColorSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isLoading && index == _messages.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildBubble(_messages[index]);
                          },
                        ),
                ),
                // Aperçu de la pièce jointe prête à l'envoi
                if (_selectedAttachmentPath != null) _buildAttachmentPreview(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Bouton d'attachement '+' (désactivé si hors ligne ou chargement)
                      if (!_isOffline)
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primaryDark,
                            size: 32,
                          ),
                          tooltip: 'Joindre un fichier',
                          onPressed: _isLoading ? null : _showAttachmentMenu,
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_isLoading && !_isOffline,
                          style: TextStyle(
                            color: _isOffline ? AppColors.textColorSecondary : AppColors.textColorPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: _isOffline
                                ? 'Mode hors-ligne - Pocam237 indisponible'
                                : 'Posez votre question à Pocam237...',
                            hintStyle: TextStyle(
                              color: _isOffline ? Colors.orange.shade700 : AppColors.hintText,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              borderSide: BorderSide(
                                color: _isOffline ? AppColors.activeIconColorPink : AppColors.inputBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              borderSide: BorderSide(
                                color: _isOffline ? AppColors.activeIconColorPink : AppColors.inputBorder,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                              borderSide: BorderSide(
                                color: AppColors.inputFocusedBorder,
                              ),
                            ),
                            filled: true,
                            fillColor: _isOffline
                                ? AppColors.activeIconColorPink.withAlpha((0.05 * 255).round())
                                : AppColors.inputBackground,
                            prefixIcon: _isOffline
                                ? const Icon(Icons.cloud_off, color: AppColors.activeIconColorPink)
                                : null,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: _isLoading || _isOffline ? null : _sendMessage,
                        mini: true,
                        backgroundColor: _isOffline || _isLoading
                            ? Colors.grey.shade400
                            : AppColors.primaryDark,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
