import 'dart:convert';
import 'package:flutter/material.dart';
import 'documents_list_page.dart';
import '../services/document_service.dart';
import '../services/openrouter_service.dart';
import '../config/api_config.dart';
import '../utils/app_theme.dart';

/// Document Summary View Page
/// Shows only the summary in PDF format - no chat functionality
class DocumentSummaryView extends StatefulWidget {
  final Document document;

  const DocumentSummaryView({
    super.key,
    required this.document,
  });

  @override
  State<DocumentSummaryView> createState() => _DocumentSummaryViewState();
}

class _DocumentSummaryViewState extends State<DocumentSummaryView> {
  final DocumentService _documentService = DocumentService();
  OpenRouterService? _openRouterService;
  String? _generatedSummary;
  bool _isLoading = true;
  bool _isGeneratingSummary = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrGenerateSummary();
    });
  }

  void _initializeService() {
    try {
      final apiKey = ApiConfig.openRouterApiKey;
      final model = ApiConfig.openRouterModel;
      _openRouterService = OpenRouterService(apiKey: apiKey, model: model);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize AI service: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrGenerateSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // According to API docs: GET /document/allDocsMetaData returns summary and extracted_text
      final documentData = await _documentService.getDocumentData(widget.document.id);
      final existingSummary = documentData['summary'];
      final extractedText = documentData['extracted_text'];

      if (existingSummary != null && existingSummary.trim().isNotEmpty) {
        // Summary exists in database, use it immediately
        if (mounted) {
          setState(() {
            _generatedSummary = existingSummary;
            _isLoading = false;
            _isGeneratingSummary = false;
          });
        }
        return;
      }

      // No summary exists - generate one using extracted_text
      if (extractedText == null || extractedText.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No summary found and extracted text is not available. Cannot generate summary.';
            _isLoading = false;
            _isGeneratingSummary = false;
          });
        }
        return;
      }

      // Generate summary using extracted text
      if (_openRouterService == null) {
        setState(() {
          _errorMessage = 'AI service not available. Please check your API key.';
          _isLoading = false;
          _isGeneratingSummary = false;
        });
        return;
      }

      setState(() {
        _isGeneratingSummary = true;
        _isLoading = false;
      });

      // Generate summary with extracted text using improved prompt
      final summary = await _openRouterService!.generateSummary(
        documentTitle: widget.document.title,
        documentContent: extractedText,
      );

      // Save summary to database according to API docs: PUT /document/edit/:documentID
      await _documentService.updateDocumentSummary(widget.document.id, summary);

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
          _isLoading = false;
          _errorMessage = 'Failed to load or generate summary: $e';
        });
      }
    }
  }

  Future<void> _regenerateSummary() async {
    if (_openRouterService == null) {
      setState(() {
        _errorMessage = 'AI service not available. Please check your API key.';
      });
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
      _errorMessage = null;
    });

    try {
      // Get extracted text from database
      final documentData = await _documentService.getDocumentData(widget.document.id);
      final extractedText = documentData['extracted_text'];

      if (extractedText == null || extractedText.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No extracted text available for this document. Cannot generate summary.';
            _isGeneratingSummary = false;
          });
        }
        return;
      }

      // Generate new summary
      final summary = await _openRouterService!.generateSummary(
        documentTitle: widget.document.title,
        documentContent: extractedText,
      );

      // Save new summary to database
      await _documentService.updateDocumentSummary(widget.document.id, summary);

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
          _errorMessage = 'Failed to regenerate summary: $e';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.summarize, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    widget.document.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: (_isLoading || _isGeneratingSummary)
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.cyan],
                    ),
              color: (_isLoading || _isGeneratingSummary)
                  ? AppColors.textSecondary
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: (_isLoading || _isGeneratingSummary)
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Regenerate Summary',
              onPressed: (_isLoading || _isGeneratingSummary) ? null : _regenerateSummary,
            ),
          ),
        ],
      ),
      body: (_isLoading || _isGeneratingSummary)
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _generatedSummary != null
                  ? _buildSummaryPDFView()
                  : _buildEmptyView(),
    );
  }

  Widget _buildLoadingView() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _isGeneratingSummary ? 'Generating summary...' : 'Loading summary...',
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isGeneratingSummary 
                ? 'Please wait while AI analyzes your document'
                : 'Checking for existing summary...',
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrGenerateSummary,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No summary available',
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPDFView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.blue50.withOpacity(0.3),
                ],
                stops: const [0.0, 0.3],
              ),
        color: isDark ? AppColors.backgroundDark : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Title with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.summarize, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Document Summary',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Summary Content
              _buildFormattedSummary(_generatedSummary!),
            ],
          ),
        ),
      ),
    );
  }

  /// Cleans markdown artifacts from text to make it readable
  String _cleanMarkdown(String text) {
    // Remove markdown tables (| col1 | col2 | and |---|---|)
    text = text.replaceAllMapped(RegExp(r'\|[^\n]*\|', multiLine: true), (match) {
      final line = match.group(0) ?? '';
      // If it's a table separator (|---| or |:---:|), remove it
      if (RegExp(r'^\|[\s:|-]+\|$').hasMatch(line)) {
        return '';
      }
      // Otherwise, remove the pipes and keep the content
      return line.replaceAll('|', ' ').trim();
    });
    
    // Remove markdown horizontal rules (___ or --- or ***)
    text = text.replaceAll(RegExp(r'^_{3,}$', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^-{3,}$', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\*{3,}$', multiLine: true), '');
    
    // Remove markdown code blocks first (```code```)
    text = text.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? '');
    
    // Remove markdown links [text](url) -> text
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (match) {
      return match.group(1) ?? '';
    });
    
    // Remove markdown images ![alt](url) -> alt
    text = text.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^\)]+\)'), (match) {
      return match.group(1) ?? '';
    });
    
    // Remove markdown strikethrough (~~text~~)
    text = text.replaceAllMapped(RegExp(r'~~(.*?)~~'), (match) {
      return match.group(1) ?? '';
    });
    
    // Remove markdown bold (**text** or __text__) - keep the text
    text = text.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) {
      return match.group(1) ?? '';
    });
    text = text.replaceAllMapped(RegExp(r'__(.*?)__'), (match) {
      return match.group(1) ?? '';
    });
    
    // Remove markdown italic (*text* or _text_) - keep the text
    text = text.replaceAllMapped(RegExp(r'(?<!\*)\*(?!\*)([^*]+?)(?<!\*)\*(?!\*)'), (match) {
      return match.group(1) ?? '';
    });
    text = text.replaceAllMapped(RegExp(r'(?<!_)_(?!_)([^_]+?)(?<!_)_(?!_)'), (match) {
      return match.group(1) ?? '';
    });
    
    // Remove markdown blockquotes (> text)
    text = text.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    
    // Remove remaining standalone asterisks, underscores, pipes (unless they're part of words)
    text = text.replaceAll(RegExp(r'(?<!\w)[*_|]{1,3}(?!\w)'), '');
    
    // Clean up extra whitespace
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r' {2,}'), ' ');
    text = text.replaceAll(RegExp(r'\$\d+'), ''); // Remove any remaining $1, $2, etc.
    
    return text.trim();
  }

  Widget _buildFormattedSummary(String summary) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Try to parse as JSON first (new structured format)
    try {
      final jsonData = jsonDecode(summary);
      if (jsonData is Map && jsonData.containsKey('sections')) {
        return _buildStructuredSummary(jsonData['sections'] as List, isDark);
      }
    } catch (e) {
      // Not JSON, fall back to old parsing method
    }
    
    // Fallback: parse as plain text (for existing summaries)
    return _buildLegacyFormattedSummary(summary, isDark);
  }
  
  Widget _buildStructuredSummary(List<dynamic> sections, bool isDark) {
    final List<Widget> widgets = [];
    
    for (var section in sections) {
      if (section is! Map) continue;
      
      final type = section['type'] as String?;
      if (type == null) continue;
      
      switch (type) {
        case 'heading':
          final text = section['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            widgets.add(_buildHeading(text.trim(), isDark));
          }
          break;
          
        case 'paragraph':
          final text = section['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            widgets.add(_buildParagraph(text.trim(), isDark, widgets.isEmpty));
          }
          break;
          
        case 'list':
          final items = section['items'] as List?;
          if (items != null && items.isNotEmpty) {
            final listItems = items
                .where((item) => item is String && item.trim().isNotEmpty)
                .map((item) => (item as String).trim())
                .toList();
            if (listItems.isNotEmpty) {
              widgets.add(_buildList(listItems, isDark));
            }
          }
          break;
      }
    }
    
    if (widgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No content available',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
  
  Widget _buildLegacyFormattedSummary(String summary, bool isDark) {
    // Clean the summary from markdown artifacts
    final cleanedSummary = _cleanMarkdown(summary);
    
    // Split into lines to process
    final lines = cleanedSummary.split('\n');
    final List<Widget> widgets = [];
    String currentParagraph = '';
    bool inList = false;
    final List<String> listItems = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        // Flush current paragraph or list
        if (inList && listItems.isNotEmpty) {
          widgets.add(_buildList(listItems, isDark));
          listItems.clear();
          inList = false;
        } else if (currentParagraph.isNotEmpty) {
          widgets.add(_buildParagraph(currentParagraph, isDark, false));
          currentParagraph = '';
        }
        continue;
      }
      
      // Check if it's a list item
      if (RegExp(r'^[-*•]\s+').hasMatch(line) || RegExp(r'^\d+\.\s+').hasMatch(line)) {
        if (!inList && currentParagraph.isNotEmpty) {
          widgets.add(_buildParagraph(currentParagraph, isDark, false));
          currentParagraph = '';
        }
        inList = true;
        final cleanedItem = line.replaceAll(RegExp(r'^[-*•]\s+'), '')
            .replaceAll(RegExp(r'^\d+\.\s+'), '').trim();
        if (cleanedItem.isNotEmpty) {
          listItems.add(cleanedItem);
        }
        continue;
      }
      
      // Regular text
      if (inList) {
        widgets.add(_buildList(listItems, isDark));
        listItems.clear();
        inList = false;
      }
      
      if (currentParagraph.isNotEmpty) {
        currentParagraph += ' ';
      }
      currentParagraph += line;
    }
    
    // Flush remaining content
    if (inList && listItems.isNotEmpty) {
      widgets.add(_buildList(listItems, isDark));
    } else if (currentParagraph.isNotEmpty) {
      widgets.add(_buildParagraph(currentParagraph, isDark, false));
    }
    
    if (widgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No content available',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
  
  Widget _buildHeading(String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 20),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.cyan],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                letterSpacing: 0.3,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildList(List<String> items, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.surfaceDarkVariant.withOpacity(0.4)
            : AppColors.blue50.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDarkVariant.withOpacity(0.15)
              : AppColors.primary.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 14),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.cyan],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.75,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      letterSpacing: 0.1,
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
  
  Widget _buildParagraph(String text, bool isDark, bool isFirst) {
    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 0,
        bottom: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          height: 1.85,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}
