// lib/screens/ia/pocam_chat_page.dart

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool isHelpful;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.attachmentPath,
    this.attachmentType,
    this.isHelpful = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PocamChatPage extends StatefulWidget {
  const PocamChatPage({super.key});

  @override
  State<PocamChatPage> createState() => _PocamChatPageState();
}

class _PocamChatPageState extends State<PocamChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _convSearchController = TextEditingController();
  final ChatEngine _engine = ChatEngine();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final List<Message> _messages = [];
  List<Map<String, dynamic>> _conversationsList = [];
  List<Map<String, dynamic>> _filteredConversationsList = [];
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

  // Suggestions rapides pour le démarrage
  final List<Map<String, String>> _quickSuggestions = [
    {
      'title': 'Garde à vue & Prolongation',
      'query': 'Quelles sont les durées légales de la garde à vue au Cameroun et la procédure de prolongation selon le Code de Procédure Pénale ?',
      'icon': '⚖️',
    },
    {
      'title': 'Perquisition sans mandat',
      'query': 'Dans quels cas précis un Officier de Police Judiciaire peut-il effectuer une perquisition sans mandat préalable au Cameroun ?',
      'icon': '🔍',
    },
    {
      'title': 'Flagrant délit (Art. 103 CPP)',
      'query': 'Comment est défini le flagrant délit selon l\'article 103 du Code de Procédure Pénale camerounais et quelles sont les prérogatives immédiates de l\'OPJ ?',
      'icon': '🚨',
    },
    {
      'title': 'Mentions obligatoires d\'un P.V.',
      'query': 'Quelles sont les mentions légales obligatoires à peine de nullité dans la rédaction d\'un procès-verbal d\'audition de suspect ?',
      'icon': '📝',
    },
    {
      'title': 'Usage légitime de la force',
      'query': 'Quelles sont les conditions strictes de l\'usage légitime de la force et des armes à feu par un fonctionnaire de police en service ?',
      'icon': '🛡️',
    },
    {
      'title': 'Contrôle routier & Saisie',
      'query': 'Quelles sont les règles de procédure pour la rétention ou la saisie de pièces d\'un véhicule lors d\'un contrôle de sécurité routière ?',
      'icon': '🚗',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initChatSession();
    _initConnectivity();
    _convSearchController.addListener(_filterConversations);
  }

  void _filterConversations() {
    final query = _convSearchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversationsList = List.from(_conversationsList);
      } else {
        _filteredConversationsList = _conversationsList.where((conv) {
          final title = (conv['title'] as String? ?? '').toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
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
    _convSearchController.dispose();
    super.dispose();
  }

  /// Initialise la session de chat : charge l'historique ou crée une conversation par défaut.
  Future<void> _initChatSession() async {
    try {
      await _loadConversations();
      if (_conversationsList.isNotEmpty) {
        final lastConvId = _conversationsList.first['id'] as int;
        await _selectConversation(lastConvId);
      } else {
        await _startNewConversation();
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    }
  }

  /// Charge toutes les sessions de conversation de la base de données locale.
  Future<void> _loadConversations() async {
    final list = await _dbHelper.getConversations();
    if (!mounted) return;
    setState(() {
      _conversationsList = list;
      _filteredConversationsList = List.from(list);
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
      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  /// Renomme une discussion existante.
  Future<void> _renameConversation(int id, String currentTitle) async {
    final titleController = TextEditingController(text: currentTitle);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primaryDark),
            SizedBox(width: 8),
            Text('Renommer le sujet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Titre de la discussion',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                await _dbHelper.updateConversationTitle(id, newTitle);
                await _loadConversations();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Supprime définitivement un fil de discussion.
  Future<void> _deleteConversation(int id) async {
    try {
      await _dbHelper.deleteConversation(id);
      await _loadConversations();

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
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Ouvre le menu modal pour attacher des images ou documents.
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Pièce jointe pour l\'enquête / analyse',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, color: AppColors.primaryDark),
                ),
                title: const Text('Prendre une photo (Constat / Pièce)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Analyse multimodale instantanée'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.teal),
                ),
                title: const Text('Sélectionner dans la galerie', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Photo existante ou capture de document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text('Joindre un document (Rapport, Loi, P.V.)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Fichiers .txt, .pdf, .docx, .json'),
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 75,
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
          SnackBar(content: Text("Erreur lors de la capture : $e")),
        );
      }
    }
  }

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

  /// Déclenche l'envoi d'un message direct ou d'une suggestion.
  Future<void> _sendMessage({String? customPrompt}) async {
    final text = customPrompt ?? _controller.text.trim();
    if ((text.isEmpty && _selectedAttachmentPath == null) ||
        _isLoading ||
        _isOffline ||
        _currentConversationId == null) {
      return;
    }

    final isFirstMessage = _messages.isEmpty;
    final String? attachmentPath = _selectedAttachmentPath;
    final String? attachmentType = _selectedAttachmentType;
    final String? attachmentName = _selectedAttachmentName;

    try {
      await _dbHelper.insertMessage(
        _currentConversationId!,
        text,
        true,
        attachmentPath: attachmentPath,
        attachmentType: attachmentType,
      );

      if (isFirstMessage) {
        String newTitle = text.isNotEmpty
            ? text
            : (attachmentType == 'image' ? "Image de constatation" : "Document : $attachmentName");
        final words = newTitle.split(' ');
        if (words.length > 5) {
          newTitle = "${words.take(5).join(' ')}...";
        } else if (newTitle.length > 28) {
          newTitle = "${newTitle.substring(0, 28)}...";
        }
        await _dbHelper.updateConversationTitle(_currentConversationId!, newTitle);
        await _loadConversations();
      }

      final historyList = _messages.map((m) => {
            'text': m.text,
            'is_user': m.isUser ? 1 : 0,
          }).toList();

      setState(() {
        _messages.add(Message(
          text: text,
          isUser: true,
          attachmentPath: attachmentPath,
          attachmentType: attachmentType,
        ));
        _isLoading = true;
        if (customPrompt == null) {
          _controller.clear();
        }
        _selectedAttachmentPath = null;
        _selectedAttachmentType = null;
        _selectedAttachmentName = null;
      });
      _scrollToBottom();

      final response = await _engine.sendMessage(
        text,
        history: historyList,
        attachmentPath: attachmentPath,
        attachmentType: attachmentType,
      );

      await _dbHelper.insertMessage(_currentConversationId!, response, false);

      if (mounted) {
        setState(() {
          _messages.add(Message(text: response, isUser: false));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Chat Error: $e');
      if (mounted) {
        setState(() {
          _messages.add(Message(
            text: "Désolé, une erreur réseau est survenue lors de la communication avec Pocam237. Veuillez vérifier votre connexion et réessayer.",
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
    _scrollToBottom();
  }

  /// Partage une réponse de l'IA sur WhatsApp
  Future<void> _shareOnWhatsApp(String text) async {
    final cleanText = text.replaceAll('*', '');
    final encodedText = Uri.encodeComponent(
      "📌 *Note Juridique & Procédurale Pocam237 (SECUR.IA)* :\n\n$cleanText\n\n_Assistance Police Camerounaise_",
    );
    final Uri uri = Uri.parse("https://wa.me/?text=$encodedText");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Impossible d'ouvrir WhatsApp";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de partage : $e")),
        );
      }
    }
  }

  /// Construit la section d'accueil avec les suggestions rapides si la discussion est vide.
  Widget _buildEmptyStateWithSuggestions() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withAlpha((0.2 * 255).round()),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 46,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/Pocam.jpg'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pocam237 • Assistant Police',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Intelligence Artificielle Juridique & Opérationnelle DGSN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Cas pratiques & requêtes courantes :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _quickSuggestions[index];
                return InkWell(
                  onTap: () {
                    _sendMessage(customPrompt: item['query']);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.02 * 255).round()),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(item['icon']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Découpe et met en forme les 3 rubriques juridiques dans des cartes élégantes
  Widget _buildStructuredAiContent(String fullText) {
    // Normaliser les séparateurs pour la détection
    final textLower = fullText.toLowerCase();

    final bool hasSections = textLower.contains('contexte') ||
        textLower.contains('référence légale') ||
        textLower.contains('procédure') ||
        textLower.contains('remarque') ||
        textLower.contains('avertissement');

    if (!hasSections) {
      return SelectableText(
        fullText.replaceAll('**', ''),
        style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1E293B)),
      );
    }

    // Extraction des 3 blocs
    final List<Widget> sectionWidgets = [];
    final lines = fullText.split('\n');

    String currentSectionType = 'intro';
    StringBuffer currentBuffer = StringBuffer();

    void flushSection() {
      final content = currentBuffer.toString().trim();
      if (content.isNotEmpty) {
        if (currentSectionType == 'contexte') {
          sectionWidgets.add(_buildSectionBox(
            title: 'RÉFÉRENCE LÉGALE & CADRE JURIDIQUE',
            icon: Icons.gavel_rounded,
            color: const Color(0xFF1E3A8A), // Bleu Marine profond
            bgColor: const Color(0xFFEFF6FF), // Fond bleu très doux
            content: content,
          ));
        } else if (currentSectionType == 'procedure') {
          sectionWidgets.add(_buildSectionBox(
            title: 'PROCÉDURE & DÉMARCHE OPÉRATIONNELLE',
            icon: Icons.checklist_rounded,
            color: const Color(0xFF0F766E), // Émeraude / Sarcelle institutionnel
            bgColor: const Color(0xFFF0FDFA),
            content: content,
          ));
        } else if (currentSectionType == 'remarque') {
          sectionWidgets.add(_buildSectionBox(
            title: 'ATTENTION & VIGILANCE DÉONTOLOGIQUE',
            icon: Icons.shield_outlined,
            color: const Color(0xFFB45309), // Ambre foncé
            bgColor: const Color(0xFFFFFBEB),
            content: content,
          ));
        } else {
          sectionWidgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableText(
              content.replaceAll('**', ''),
              style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1E293B)),
            ),
          ));
        }
      }
      currentBuffer.clear();
    }

    for (var line in lines) {
      final lineClean = line.replaceAll('**', '').replaceAll('#', '').trim();
      final lower = lineClean.toLowerCase();

      if (lower.startsWith('contexte') || lower.startsWith('référence légale') || lower.startsWith('🧭 contexte')) {
        flushSection();
        currentSectionType = 'contexte';
        final colonIndex = lineClean.indexOf(':');
        if (colonIndex != -1 && colonIndex < lineClean.length - 1) {
          currentBuffer.writeln(lineClean.substring(colonIndex + 1).trim());
        }
      } else if (lower.startsWith('procédure') || lower.startsWith('reponse') || lower.startsWith('réponse') || lower.startsWith('🧾 procédure')) {
        flushSection();
        currentSectionType = 'procedure';
        final colonIndex = lineClean.indexOf(':');
        if (colonIndex != -1 && colonIndex < lineClean.length - 1) {
          currentBuffer.writeln(lineClean.substring(colonIndex + 1).trim());
        }
      } else if (lower.startsWith('remarque') || lower.startsWith('avertissement') || lower.startsWith('⚠️ remarque')) {
        flushSection();
        currentSectionType = 'remarque';
        final colonIndex = lineClean.indexOf(':');
        if (colonIndex != -1 && colonIndex < lineClean.length - 1) {
          currentBuffer.writeln(lineClean.substring(colonIndex + 1).trim());
        }
      } else {
        currentBuffer.writeln(lineClean);
      }
    }
    flushSection();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionWidgets,
    );
  }

  Widget _buildSectionBox({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.25 * 255).round()), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.08 * 255).round()),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bulle de message principale
  Widget _buildBubble(Message message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.attachmentPath != null) ...[
                _buildMessageAttachment(message),
                const SizedBox(height: 8),
              ],
              if (message.text.isNotEmpty)
                SelectableText(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    } else {
      // Bulle Réponse Pocam237
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD97706), width: 1.5),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('assets/images/logo_police.jpg'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.03 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pocam237',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStructuredAiContent(message.text),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    // Barre d'actions rapides (Copier, WhatsApp, Feedback)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Réponse copiée dans le presse-papiers !'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 15, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('Copier', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _shareOnWhatsApp(message.text),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.share_rounded, size: 15, color: Color(0xFF25D366)),
                                const SizedBox(width: 4),
                                const Text('WhatsApp', style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            message.isHelpful ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                            size: 16,
                            color: message.isHelpful ? Colors.green : Colors.grey.shade400,
                          ),
                          onPressed: () {
                            setState(() {
                              message.isHelpful = !message.isHelpful;
                            });
                            if (message.isHelpful) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Merci pour votre retour positif !'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMessageAttachment(Message message) {
    final String path = message.attachmentPath!;
    final String type = message.attachmentType!;
    final String name = path.split(Platform.pathSeparator).last;

    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 180),
          width: double.infinity,
          child: Image.file(File(path), fit: BoxFit.cover),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Tiroir latéral (Drawer) réorganisé avec recherche et regroupement chronologique
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Image.asset('assets/images/logo_police.jpg'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pocam237 • DGSN',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Historique des requêtes',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bouton Nouvelle Discussion
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _startNewConversation();
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nouvelle discussion', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Barre de recherche dans l'historique
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _convSearchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une discussion...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(),
          // Liste des discussions
          Expanded(
            child: _filteredConversationsList.isEmpty
                ? Center(
                    child: Text(
                      _convSearchController.text.isEmpty
                          ? 'Aucune discussion enregistrée'
                          : 'Aucun résultat trouvé',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredConversationsList.length,
                    itemBuilder: (context, index) {
                      final conv = _filteredConversationsList[index];
                      final id = conv['id'] as int;
                      final title = conv['title'] as String;
                      final isSelected = id == _currentConversationId;

                      return ListTile(
                        leading: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade500,
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDark : AppColors.textColorPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: const Color(0xFFEFF6FF),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                              tooltip: 'Renommer',
                              onPressed: () => _renameConversation(id, title),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              tooltip: 'Supprimer',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Supprimer la discussion'),
                                    content: const Text('Confirmez-vous la suppression définitive de cette discussion ?'),
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
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _selectConversation(id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Indicateur animé de réflexion (3 petits points pulsants)
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD97706), width: 1.5),
            ),
            child: const CircleAvatar(
              radius: 14,
              backgroundImage: AssetImage('assets/images/logo_police.jpg'),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 10),
                Text(
                  "Pocam237 analyse la requête...",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedAttachmentType == 'image' ? 'Image de constatation prête' : 'Document d\'enquête prêt',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
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
      backgroundColor: const Color(0xFFF8FAFC), // Fond gris très clair moderne
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/logo_police.jpg'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pocam237',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _isOffline ? 'Mode hors-ligne' : 'IA Juridique active',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isOffline ? Colors.orangeAccent : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Accueil SecurIA',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainHomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bannière hors-ligne animée
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isOffline ? 44.0 : 0.0,
                  color: const Color(0xFFD97706),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 44.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Mode hors-ligne - Assistant indisponible (Annuaire 100% accessible)",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                      ? _buildEmptyStateWithSuggestions()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isLoading && index == _messages.length) {
                              return _buildTypingIndicator();
                            }
                            return _buildBubble(_messages[index]);
                          },
                        ),
                ),
                if (_selectedAttachmentPath != null) _buildAttachmentPreview(),
                // Barre de saisie inférieure
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.05 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryDark, size: 28),
                          tooltip: 'Joindre une pièce',
                          onPressed: _isLoading || _isOffline ? null : _showAttachmentMenu,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_isLoading && !_isOffline,
                            maxLines: 4,
                            minLines: 1,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: _isOffline
                                  ? 'Mode hors-ligne - Assistant indisponible'
                                  : 'Posez votre question à Pocam237...',
                              hintStyle: TextStyle(
                                color: _isOffline ? Colors.orange.shade700 : Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          onPressed: _isLoading || _isOffline ? null : () => _sendMessage(),
                          mini: true,
                          elevation: 2,
                          backgroundColor: _isOffline || _isLoading ? Colors.grey.shade400 : AppColors.primaryDark,
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
