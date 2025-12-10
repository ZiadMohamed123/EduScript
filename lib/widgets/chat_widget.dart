import 'package:flutter/material.dart';
import '../screens/documents_list_page.dart';
import '../utils/app_theme.dart';

class ChatWidget extends StatefulWidget {
  final Document? document;

  const ChatWidget({super.key, this.document});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isExpanded = false;
  Document? _selectedDocument;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.document;
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
  }

  @override
  void didUpdateWidget(ChatWidget oldWidget) {
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
              ? 'Hi! I can help you with "${_selectedDocument!.title}". Ask me to summarize, generate MCQ questions, or explain concepts!'
              : 'Hi! I\'m your AI assistant. I can help you summarize documents, generate MCQ questions, and answer questions about your scanned notes.',
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade600,
                    child: const Icon(
                      Icons.smart_toy,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Chat for summaries & questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Chat Content (expandable)
          if (_isExpanded) ...[
            // Quick Actions
            if (_selectedDocument != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
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
                        label: 'MCQ',
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
            Container(
              height: 300,
              padding: const EdgeInsets.all(12),
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
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
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        size: 18,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
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
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.smart_toy, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.blue.shade600
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12).copyWith(
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(12),
                  bottomLeft: message.isUser
                      ? const Radius.circular(12)
                      : const Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
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
      avatar: Icon(icon, size: 16, color: Colors.blue.shade600),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.blue.shade200),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
