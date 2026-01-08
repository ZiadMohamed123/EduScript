import 'package:flutter/material.dart';
import 'documents_list_page.dart';
import '../services/openrouter_service.dart';
import '../services/document_service.dart';
import '../config/api_config.dart';

class SummaryPage extends StatefulWidget {
  final Document? document;

  const SummaryPage({super.key, this.document});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final DocumentService _documentService = DocumentService();
  bool _isLoading = false;
  Document? _selectedDocument;
  OpenRouterService? _openRouterService;
  String? _generatedSummary;
  bool _isGeneratingSummary = false;
  bool _showSummaryView = false;

  bool _isServiceInitialized() {
    return _openRouterService != null;
  }

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.document;
    _initializeService();

    // Auto-generate summary if document is provided
    if (_selectedDocument != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateSummaryAutomatically();
      });
    } else {
      _addWelcomeMessage();
    }
  }

  void _initializeService() {
    try {
      final apiKey = ApiConfig.openRouterApiKey;
      final model = ApiConfig.openRouterModel;
      debugPrint(
        'Initializing OpenRouter service with key: ${apiKey.substring(0, 10)}...',
      );
      debugPrint('Using model: $model');
      _openRouterService = OpenRouterService(apiKey: apiKey, model: model);
      debugPrint('✓ OpenRouter service initialized successfully');
    } catch (e, stackTrace) {
      // API key not configured - will show error when user tries to chat
      debugPrint('✗ Error initializing OpenRouter service: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  void didUpdateWidget(SummaryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.document != oldWidget.document) {
      _selectedDocument = widget.document;
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          text: _selectedDocument != null
              ? 'Hi! I\'m your AI tutor. I can help you understand "${_selectedDocument!.title}". '
                  'Ask me any questions about this document:\n\n'
                  '• What are the main concepts?\n'
                  '• Can you explain [specific topic]?\n'
                  '• How does [concept] work?\n'
                  '• What is the relationship between [topic A] and [topic B]?\n'
                  '• Can you give me examples of [concept]?\n'
                  '• Help me understand [difficult section]'
              : 'Hi! I\'m your AI tutor. I\'m here to answer your questions and help you learn! '
                  'Select a document to get started, or ask me any questions about your studies.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _generateSummaryAutomatically() async {
    if (_selectedDocument == null) {
      _addWelcomeMessage();
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
      _showSummaryView = true;
    });

    try {
      // According to API docs: GET /document/allDocsMetaData returns summary and extracted_text
      final documentData =
          await _documentService.getDocumentData(_selectedDocument!.id);
      final existingSummary = documentData['summary'];
      final extractedText = documentData['extracted_text'];

      if (existingSummary != null && existingSummary.trim().isNotEmpty) {
        // Summary exists in database, use it immediately
        if (mounted) {
          setState(() {
            _generatedSummary = existingSummary;
            _isGeneratingSummary = false;
          });
        }
        return;
      }

      // No summary exists - generate one using extracted_text
      if (extractedText == null || extractedText.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isGeneratingSummary = false;
            _showSummaryView = false;
          });
          _addWelcomeMessage();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No summary found and extracted text is not available. Cannot generate summary.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate summary if service is available
      if (!_isServiceInitialized()) {
        if (mounted) {
          setState(() {
            _isGeneratingSummary = false;
            _showSummaryView = false;
          });
          _addWelcomeMessage();
        }
        return;
      }

      // Generate new summary using extracted text
      final summary = await _openRouterService!.generateSummary(
        documentTitle: _selectedDocument!.title,
        documentContent: extractedText,
      );

      // Save summary to database according to API docs: PUT /document/edit/:documentID
      await _documentService.updateDocumentSummary(
          _selectedDocument!.id, summary);

      if (mounted) {
        setState(() {
          _generatedSummary = summary;
          _isGeneratingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
          _showSummaryView = false;
        });
        _addWelcomeMessage();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load summary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Generate AI response using OpenRouter
    _generateResponse(text);
  }

  Future<void> _generateResponse(String userMessage) async {
    // Check if service is initialized
    if (!mounted) return;

    try {
      // Initialize service if not already done
      if (!_isServiceInitialized()) {
        debugPrint('Service not initialized, initializing now...');
        _initializeService();
        if (!_isServiceInitialized()) {
          throw Exception(
            'Failed to initialize OpenRouter service. Check API key configuration.',
          );
        }
      }

      final lowerMessage = userMessage.toLowerCase();

      // Build conversation history
      final conversationHistory = _messages
          .where(
            (msg) => msg.text != _messages.first.text,
          ) // Exclude welcome message
          .map(
            (msg) => {
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.text,
            },
          )
          .toList();

      String response = '';

      // Ensure service is initialized
      if (_openRouterService == null) {
        throw Exception(
          'OpenRouter service not initialized. Check API key configuration.',
        );
      }

      // Handle specific requests with dedicated methods
      if (lowerMessage.contains('summary') ||
          lowerMessage.contains('summarize')) {
        if (_selectedDocument != null) {
          // First check if summary exists in database
          try {
            final documentData =
                await _documentService.getDocumentData(_selectedDocument!.id);
            final existingSummary = documentData['summary'];
            final extractedText = documentData['extracted_text'];

            if (existingSummary != null && existingSummary.trim().isNotEmpty) {
              response = existingSummary;
            } else if (extractedText != null &&
                extractedText.trim().isNotEmpty) {
              // No summary exists, generate one using extracted_text
              response = await _openRouterService!.generateSummary(
                documentTitle: _selectedDocument!.title,
                documentContent: extractedText,
              );
              // Save generated summary to database
              await _documentService.updateDocumentSummary(
                  _selectedDocument!.id, response);
            } else {
              response =
                  'No summary found and extracted text is not available. Cannot generate summary.';
            }
          } catch (e) {
            // If database check fails, try generating without extracted_text
            response = await _openRouterService!.generateSummary(
              documentTitle: _selectedDocument!.title,
            );
          }
        } else {
          response = await _openRouterService!.tutorChat(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
          );
        }
      } else if (lowerMessage.contains('study notes') ||
          lowerMessage.contains('create study notes') ||
          lowerMessage.contains('key points')) {
        if (_selectedDocument != null) {
          response = await _openRouterService!.generateSummary(
            documentTitle: _selectedDocument!.title,
          );
        } else {
          response = await _openRouterService!.tutorChat(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
          );
        }
      } else if (lowerMessage.contains('explain') ||
          lowerMessage.contains('what is') ||
          lowerMessage.contains('how does') ||
          lowerMessage.contains('tell me about')) {
       

        response = await _openRouterService!.tutorChat(
          userMessage: userMessage,
          conversationHistory: conversationHistory,
        );
      } else {
        // General chat
        response = await _openRouterService!.tutorChat(
          userMessage: userMessage,
          conversationHistory: conversationHistory,
          documentTitle: _selectedDocument?.title,
        );
      }

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e, stackTrace) {
      if (mounted) {
       

        String errorMessage = 'Sorry, I encountered an error.\n\n';

        if (e.toString().contains('not found') ||
            e.toString().contains('not loaded') ||
            e.toString().contains('not initialized') ||
            e.toString().contains('Failed to initialize')) {
          errorMessage += '**API Key Not Configured**\n\n'
              'Please:\n'
              '1. Get your free API key from: https://openrouter.ai/keys\n'
              '2. Add it to your .env file:\n'
              '   OPENROUTER_API_KEY=your_key_here\n'
              '3. (Optional) Set model: OPENROUTER_MODEL=openai/gpt-3.5-turbo\n'
              '4. Do a FULL RESTART (stop and start, not hot reload)\n'
              '5. Check the debug console for loading messages';
        } else if (e.toString().contains('Data Policy Error') ||
            e.toString().contains('data policy') ||
            e.toString().contains('Free model publication')) {
          errorMessage += '**OpenRouter Data Policy Error**\n\n'
              'Your OpenRouter account needs to be configured for free models.\n\n'
              '**Fix this:**\n'
              '1. Go to: https://openrouter.ai/settings/privacy\n'
              '2. Enable "Free model publication" or adjust your data policy\n'
              '3. Save your settings\n'
              '4. Try again\n\n'
              '**Alternative:** Use a different free model that doesn\'t require this setting.';
        } else if (e.toString().contains('400') ||
            e.toString().contains('401') ||
            e.toString().contains('403')) {
          errorMessage += '**API Key Error**\n\n'
              'Your API key may be invalid or expired.\n\n'
              'Please:\n'
              '1. Check your API key at: https://openrouter.ai/keys\n'
              '2. Make sure it\'s correct in your .env file\n'
              '3. Verify you have credits/balance on OpenRouter\n'
              '4. Restart the app';
        } else {
          errorMessage += 'Error: ${e.toString()}\n\n'
              'Please check:\n'
              '• Your OPENROUTER_API_KEY is set correctly in .env file\n'
              '• You have internet connection\n'
              '• Your API key is valid and has credits\n'
              '• The model name is correct (check OPENROUTER_MODEL)\n'
              '• Check debug console for more details';
        }

        setState(() {
          _messages.add(
            ChatMessage(
              text: errorMessage,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _selectDocument() async {
    try {
      final documents = await DocumentService().getAllDocuments();

      if (documents.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No documents available. Scan a document first!'),
            ),
          );
        }
        return;
      }

      final selected = await showDialog<Document>(
        context: context,
        builder: (context) => _DocumentSelectorDialog(documents: documents),
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedDocument = selected;
          // Clear messages and show new welcome message for the selected document
          _messages.clear();
          _addWelcomeMessage();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load documents: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Tutor'),
            if (_selectedDocument != null)
              Text(
                _selectedDocument!.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              )
            else
              TextButton.icon(
                onPressed: _selectDocument,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text(
                  'Select a document',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: 'Select Document',
            onPressed: _selectDocument,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          final maxContentWidth = isLandscape ? 1000.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: _showSummaryView && _generatedSummary != null
                  ? _buildSummaryPDFView()
                  : Column(
                      children: [
                        // Quick Actions Bar
                        if (_selectedDocument != null && !_showSummaryView)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: scheme.surfaceVariant
                                  .withOpacity(isDark ? 0.3 : 0.8),
                              border: Border(
                                bottom:
                                    BorderSide(color: scheme.outlineVariant),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _QuickActionChip(
                                    icon: Icons.summarize,
                                    label: 'Summary',
                                    onTap: () =>
                                        _sendMessage('Generate a summary'),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickActionChip(
                                    icon: Icons.note,
                                    label: 'Study Notes',
                                    onTap: () =>
                                        _sendMessage('Create study notes'),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickActionChip(
                                    icon: Icons.help_outline,
                                    label: 'Explain',
                                    onTap: () => _sendMessage(
                                        'Explain the main concepts'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Summary Loading or Messages List
                        Expanded(
                          child: _isGeneratingSummary
                              ? _buildSummaryLoadingView()
                              : (_messages.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _messages.length +
                                          (_isLoading ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index == _messages.length) {
                                          return _buildTypingIndicator();
                                        }
                                        return _ChatBubble(
                                            message: _messages[index]);
                                      },
                                    )),
                        ),

                        // Input Area
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.4)
                                    : Colors.grey.shade300,
                                blurRadius: 6,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Ask about summaries, concepts, or study materials...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide(
                                            color: scheme.outlineVariant),
                                      ),
                                      filled: true,
                                      fillColor:
                                          scheme.surfaceVariant.withOpacity(
                                        isDark ? 0.3 : 0.7,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: isDark
                                          ? scheme.onSurface
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        _sendMessage(value);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: scheme.primary,
                                  child: IconButton(
                                    icon: Icon(Icons.send,
                                        color: scheme.onPrimary),
                                    onPressed: () =>
                                        _sendMessage(_messageController.text),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryPDFView() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Column(
      children: [
        // PDF Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDocument?.title ?? 'Document Summary',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Generated Summary',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat),
                tooltip: 'Switch to Chat',
                onPressed: () {
                  setState(() {
                    _showSummaryView = false;
                    _addWelcomeMessage();
                  });
                },
              ),
            ],
          ),
        ),

        // PDF Content
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document Title
                    Text(
                      _selectedDocument?.title ?? 'Document',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Divider(height: 32),
                    const SizedBox(height: 16),

                    // Summary Content
                    _buildFormattedSummary(_generatedSummary!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedSummary(String summary) {
    // Split summary into paragraphs and format
    final paragraphs = summary.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().isEmpty) return const SizedBox(height: 16);

        // Check if it's a heading (starts with # or is short and bold-looking)
        final isHeading = paragraph.startsWith('#') ||
            (paragraph.length < 100 &&
                !paragraph.contains('.') &&
                paragraph.split(' ').length < 10);

        if (isHeading) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Text(
              paragraph.replaceAll('#', '').trim(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        }

        // Check if it's a bullet point
        if (paragraph.trim().startsWith('-') ||
            paragraph.trim().startsWith('•')) {
          final items = paragraph.split('\n');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                if (item.trim().isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Text(
                          item.replaceAll(RegExp(r'^[-•]\s*'), '').trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }

        // Regular paragraph
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            paragraph.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryLoadingView() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating summary...',
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while AI analyzes your document',
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a document or ask me anything',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? scheme.primary
                    : scheme.surfaceVariant.withOpacity(
                        scheme.brightness == Brightness.dark ? 0.3 : 0.8,
                      ),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: message.isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          message.isUser ? scheme.onPrimary : scheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? scheme.onPrimary.withOpacity(0.75)
                          : scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.surfaceVariant,
              child: Icon(
                Icons.person,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: scheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: scheme.surface,
      side: BorderSide(color: scheme.primary.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _DocumentSelectorDialog extends StatelessWidget {
  final List<Document> documents;

  const _DocumentSelectorDialog({required this.documents});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a Document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: scheme.onPrimaryContainer),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Documents List
            Flexible(
              child: documents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents available',
                            style: TextStyle(
                              fontSize: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan a document first',
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: scheme.primary,
                            ),
                          ),
                          title: Text(
                            doc.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${doc.pageCount} ${doc.pageCount == 1 ? 'page' : 'pages'} • ${_formatDate(doc.dateCreated)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: scheme.onSurfaceVariant,
                          ),
                          onTap: () => Navigator.pop(context, doc),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
