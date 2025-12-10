import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'documents_list_page.dart';

class ChatPage extends StatefulWidget {
  final Document? document;
  final String? initialMessage;

  const ChatPage({super.key, this.document, this.initialMessage});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Document? _selectedDocument;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.document;
    _addWelcomeMessage();

    // Auto-send initial message if provided
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  void _addWelcomeMessage() {
    if (_selectedDocument != null) {
      _messages.add(
        ChatMessage(
          text:
              'Hi! I\'m your EduScript AI assistant. I can help you with "${_selectedDocument!.title}". What would you like to do?\n\n• Generate a summary\n• Create MCQ questions\n• Ask questions about the content\n• Explain specific concepts',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      _messages.add(
        ChatMessage(
          text:
              'Hi! I\'m your EduScript AI assistant. I can help you summarize documents, generate MCQ questions, and answer questions about your scanned notes.\n\nSelect a document to get started, or ask me anything!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
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

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      _generateResponse(text);
    });
  }

  void _generateResponse(String userMessage) {
    String response = '';
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('summary') ||
        lowerMessage.contains('summarize')) {
      if (_selectedDocument != null) {
        response =
            'Here\'s a summary of "${_selectedDocument!.title}":\n\n'
            '**Key Points:**\n'
            '• Main concepts covered in the document\n'
            '• Important definitions and formulas\n'
            '• Key examples and applications\n\n'
            '**Summary:**\n'
            'This document covers essential topics that build upon fundamental principles. '
            'The content is structured to provide both theoretical understanding and practical applications.\n\n'
            'Would you like me to generate MCQ questions based on this summary?';
      } else {
        response =
            'I\'d be happy to generate a summary! Please select a document first, or tell me which document you\'d like me to summarize.';
      }
    } else if (lowerMessage.contains('mcq') ||
        lowerMessage.contains('question') ||
        lowerMessage.contains('quiz')) {
      if (_selectedDocument != null) {
        response =
            'Here are some MCQ questions based on "${_selectedDocument!.title}":\n\n'
            '**Question 1:**\n'
            'What is the main topic discussed in this document?\n'
            'A) Option A\n'
            'B) Option B\n'
            'C) Option C\n'
            'D) Option D\n\n'
            '**Question 2:**\n'
            'Which concept is most important?\n'
            'A) Concept A\n'
            'B) Concept B\n'
            'C) Concept C\n'
            'D) Concept D\n\n'
            'Would you like more questions or explanations for these answers?';
      } else {
        response =
            'I can generate MCQ questions for you! Please select a document first, or tell me which document you\'d like me to create questions from.';
      }
    } else if (lowerMessage.contains('explain') ||
        lowerMessage.contains('what is') ||
        lowerMessage.contains('how')) {
      response =
          'Based on "${_selectedDocument?.title ?? "your document"}", here\'s an explanation:\n\n'
          'The concept you\'re asking about relates to the core principles discussed in the document. '
          'Let me break it down:\n\n'
          '1. **Definition:** The fundamental meaning\n'
          '2. **Application:** How it\'s used in practice\n'
          '3. **Examples:** Real-world scenarios\n\n'
          'Would you like me to elaborate on any specific aspect?';
    } else {
      response =
          'I understand you\'re asking about "${userMessage}". '
          '${_selectedDocument != null ? "Based on \"${_selectedDocument!.title}\", " : ""}'
          'I can help you with:\n\n'
          '• **Summaries** - Get concise overviews\n'
          '• **MCQ Questions** - Generate practice questions\n'
          '• **Explanations** - Understand concepts better\n'
          '• **Q&A** - Ask specific questions\n\n'
          'What would you like to do?';
    }

    setState(() {
      _messages.add(
        ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _selectDocument() async {
    // Navigate to document selection
    await Navigator.pushNamed(context, '/documents');
    // In a real app, you'd get the selected document back
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document selection feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Assistant'),
            if (_selectedDocument != null)
              Text(
                _selectedDocument!.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
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
      body: Column(
        children: [
          // Quick Actions Bar
          if (_selectedDocument != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.8),
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickActionChip(
                      icon: Icons.summarize,
                      label: 'Summary',
                      onTap: () => _sendMessage('Generate a summary'),
                    ),
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.quiz,
                      label: 'MCQ Questions',
                      onTap: () => _sendMessage('Generate MCQ questions'),
                    ),
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.help_outline,
                      label: 'Explain',
                      onTap: () => _sendMessage('Explain the main concepts'),
                    ),
                  ],
                ),
              ),
            ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
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
                      : scheme.shadow.withOpacity(0.2),
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
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? scheme.onSurfaceVariant
                              : Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        filled: true,
                        fillColor: scheme.surfaceVariant.withOpacity(
                          isDark ? 0.35 : 0.7,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? scheme.onSurface : Colors.black87,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: scheme.primary,
                    child: IconButton(
                      icon: Icon(Icons.send, color: scheme.onPrimary),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
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
            color: scheme.onSurfaceVariant.withOpacity(0.4),
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
              color: scheme.surfaceVariant.withOpacity(0.6),
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animatedValue = ((value + delay) % 1.0);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withOpacity(
              0.3 + animatedValue * 0.7,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted && _isLoading) {
          setState(() {});
        }
      },
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final textColor = message.isUser
        ? scheme.onPrimary
        : (isDark ? scheme.onSurface : Colors.black87);
    final timeColor = message.isUser
        ? scheme.onPrimary.withOpacity(0.75)
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
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
                    : scheme.surfaceVariant.withOpacity(0.7),
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
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(color: timeColor, fontSize: 11),
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
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.accent),
    );
  }
}
