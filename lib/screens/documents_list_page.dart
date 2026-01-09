import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/document_service.dart';
import 'quiz_generator_page.dart';
import 'QuizCustomizationPage.dart';
import 'SavedQuizzesListPage.dart';

class Document {
  final String id;
  final String title;
  final DateTime dateCreated;
  final String? thumbnailPath;
  final int pageCount;

  Document({
    required this.id,
    required this.title,
    required this.dateCreated,
    this.thumbnailPath,
    this.pageCount = 1,
  });
}

class DocumentsListPage extends StatefulWidget {
  final bool showRecentsOnly;

  const DocumentsListPage({
    super.key,
    this.showRecentsOnly = false,
  });

  @override
  State<DocumentsListPage> createState() => _DocumentsListPageState();
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  final DocumentService _documentService = DocumentService();
  List<Document> _documents = [];
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date' or 'name'

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Document> documents;
      if (widget.showRecentsOnly) {
        documents = await _documentService.getRecentDocuments(limit: 10);
      } else {
        documents = await _documentService.getAllDocuments();
      }

      if (mounted) {
        setState(() {
          _documents = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    final filteredDocuments = _documents.where((doc) {
      return doc.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort documents
    filteredDocuments.sort((a, b) {
      if (_sortBy == 'date') {
        return b.dateCreated.compareTo(a.dateCreated);
      } else {
        return a.title.compareTo(b.title);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.showRecentsOnly ? 'Recent Documents' : 'My Documents'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              final isDark = scheme.brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: TextStyle(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search, color: scheme.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: scheme.onSurfaceVariant),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: scheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor:
                        scheme.surfaceContainerHighest.withOpacity(isDark ? 0.3 : 0.7),
                  ),
                ),
              );
            },
          ),

          // Documents List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDocuments.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isLandscape =
                              MediaQuery.of(context).orientation ==
                                  Orientation.landscape;
                          final crossAxisCount = isLandscape
                              ? (constraints.maxWidth / 300).floor().clamp(2, 4)
                              : 1;

                          if (isLandscape && crossAxisCount > 1) {
                            // Grid layout for landscape - improved spacing
                            return GridView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    constraints.maxWidth > 800 ? 32 : 16,
                                vertical: 16,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing:
                                    constraints.maxWidth > 800 ? 24 : 16,
                                mainAxisSpacing:
                                    constraints.maxWidth > 800 ? 24 : 16,
                                childAspectRatio:
                                    constraints.maxWidth > 800 ? 1.3 : 1.2,
                              ),
                              itemCount: filteredDocuments.length,
                              itemBuilder: (context, index) {
                                return _DocumentCard(
                                  document: filteredDocuments[index],
                                  onTap: () {
                                    _showDocumentOptions(
                                        context, filteredDocuments[index]);
                                  },
                                  onDelete: () {
                                    _deleteDocument(filteredDocuments[index]);
                                  },
                                );
                              },
                            );
                          } else {
                            // List layout for portrait
                            return ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredDocuments.length,
                              itemBuilder: (context, index) {
                                return _DocumentCard(
                                  document: filteredDocuments[index],
                                  onTap: () {
                                    _showDocumentOptions(
                                        context, filteredDocuments[index]);
                                  },
                                  onDelete: () {
                                    _deleteDocument(filteredDocuments[index]);
                                  },
                                );
                              },
                            );
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No documents found' : 'No documents yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Upload a document to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentOptions(BuildContext context, Document document) {
    // Capture parent context and ScaffoldMessenger before showing modal
    final parentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.summarize),
            title: const Text('View Summary'),
            onTap: () {
              Navigator.pop(modalContext);
              Navigator.pushNamed(
                parentContext,
                '/document-summary',
                arguments: document,
              );
            },
          ),
          ListTile(
  leading: const Icon(Icons.quiz),
  title: const Text('Generate MCQ'),
  onTap: () async {
    Navigator.pop(modalContext);

    try {
      // Fetch the extracted text from the document
      final extractedText =
          await _documentService.getExtractedText(document.id);

      if (extractedText == null || extractedText.isEmpty) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                  'No text found in document. Please make sure the document has been processed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Navigate to quiz CUSTOMIZATION page first
      if (mounted) {
        Navigator.push(
          parentContext,
          MaterialPageRoute(
            builder: (_) => QuizCustomizationPage(
              documentId: document.id,
              documentTitle: document.title,
              extractedText: extractedText,
            ),
          ),
        );
      }
    } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to load document text: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('View Quizzes'),
           onTap: () {
  Navigator.pop(modalContext);
  Navigator.push(
    parentContext,
    MaterialPageRoute(
      builder: (_) => SavedQuizzesListPage(
        documentId: document.id,
      ),
    ),
  );
},
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(modalContext);
              _deleteDocument(document);
            },
          ),
        ],
      ),
    );
  }

  void _deleteDocument(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _documentService.deleteDocument(document.id);
                await _loadDocuments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to delete document: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Thumbnail/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Document Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(document.dateCreated),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.pages,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${document.pageCount} ${document.pageCount == 1 ? 'page' : 'pages'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text('View'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    onTap();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
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
