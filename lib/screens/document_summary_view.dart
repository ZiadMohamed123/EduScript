import 'package:flutter/material.dart';
import 'documents_list_page.dart';
import '../services/document_service.dart';
import '../services/openrouter_service.dart';
import '../config/api_config.dart';

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Document Summary'),
            Text(
              widget.document.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate Summary',
            onPressed: (_isLoading || _isGeneratingSummary) ? null : _regenerateSummary,
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
    return Container(
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
                widget.document.title,
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
}







