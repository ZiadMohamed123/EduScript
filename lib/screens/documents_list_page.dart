import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/document_service.dart';
import 'QuizCustomizationPage.dart';
import 'SavedQuizzesListPage.dart';
import '../providers/document_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  Document? _pendingDelete;
  bool _isDeleting = false;

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
          _documents = List<Document>.from(documents); // Create mutable copy
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
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.error_outline,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to load documents: ${e.toString()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            margin: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
          ),
        );
      }
    }
  }

  Future<void> _viewPdf(Document document) async {
    try {

      // Get the local PDF path using the document ID
      final localPdfPath = await DocumentProvider.getLocalPdfPath(document.id);

      if (localPdfPath == null || localPdfPath.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF not available. Please re-scan the document.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final file = File(localPdfPath);
      final exists = await file.exists();

      if (exists) {

        // Use platform channel to open file with FileProvider
        try {
          await const MethodChannel('com.example.edu_script/files')
              .invokeMethod('openFile', {
            'filePath': localPdfPath,
            'mimeType': 'application/pdf',
          });
        } catch (e) {

          // Fallback: Try to use launchUrl with proper encoding
          final Uri uri = Uri.parse('file://$localPdfPath');
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } else {
            throw 'Could not launch $uri';
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF file not found on device'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: ${e.toString()}'),
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.showRecentsOnly
                      ? [
                          AppColors.cyan,
                          AppColors.primary,
                          AppColors.primaryDark,
                        ]
                      : [
                          AppColors.primary,
                          AppColors.cyan,
                          AppColors.accent,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.showRecentsOnly ? Icons.history_rounded : Icons.folder,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.showRecentsOnly ? 'Recent' : 'My Documents',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.sort,
                color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                size: 22,
              ),
              padding: const EdgeInsets.all(8),
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
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.blue50.withOpacity(0.4),
                    AppColors.cyanLight.withOpacity(0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
        ),
        child: Stack(
          children: [
            // Decorative background shapes
            if (!isDark) ...[
              Positioned(
                top: 100,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cyanLight.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.indigoLight.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.25)
                              : AppColors.primary.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search documents...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary.withOpacity(0.6),
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.cyan],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.surfaceDarkVariant
                                : Colors.transparent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.surfaceDarkVariant
                                : Colors.transparent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),

                // Documents List
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : filteredDocuments.isEmpty
                          ? _buildEmptyState(isDark)
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final isLandscape =
                                    MediaQuery.of(context).orientation ==
                                        Orientation.landscape;
                                final crossAxisCount = isLandscape
                                    ? (constraints.maxWidth / 300)
                                        .floor()
                                        .clamp(2, 4)
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
                                          constraints.maxWidth > 800
                                              ? 1.3
                                              : 1.2,
                                    ),
                                    itemCount: filteredDocuments.length,
                                    itemBuilder: (context, index) {
                                      return _DocumentCard(
                                        document: filteredDocuments[index],
                                        onTap: () {
                                          _showDocumentOptions(context,
                                              filteredDocuments[index]);
                                        },
                                        onDelete: () {
                                          _deleteDocument(
                                              filteredDocuments[index]);
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  // List layout for portrait
                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: filteredDocuments.length,
                                    itemBuilder: (context, index) {
                                      return _DocumentCard(
                                        document: filteredDocuments[index],
                                        onTap: () {
                                          _showDocumentOptions(context,
                                              filteredDocuments[index]);
                                        },
                                        onDelete: () {
                                          _deleteDocument(
                                              filteredDocuments[index]);
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.cyan.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ? 'No documents found' : 'No documents yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Upload a document to get started',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentOptions(BuildContext context, Document document) {
    final parentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.cyan],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              modalContext,
              icon: Icons.picture_as_pdf,
              title: 'View PDF',
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.primaryDark],
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _viewPdf(document);
              },
            ),
            const Divider(height: 8),
            _buildActionTile(
              modalContext,
              icon: Icons.summarize,
              title: 'View Summary',
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.cyan],
              ),
              onTap: () {
                Navigator.pop(modalContext);
                Navigator.pushNamed(
                  parentContext,
                  '/document-summary',
                  arguments: document,
                );
              },
            ),
            _buildActionTile(
              modalContext,
              icon: Icons.quiz,
              title: 'Generate Quiz',
              gradient: const LinearGradient(
                colors: [AppColors.cyan, AppColors.primary],
              ),
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
                        content: Text(
                            'Failed to load document text: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            _buildActionTile(
              modalContext,
              icon: Icons.library_books,
              title: 'View Quizzes',
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.indigo],
              ),
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
            _buildActionTile(
              modalContext,
              icon: Icons.delete,
              title: 'Delete',
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              isDestructive: true,
              onTap: () {
                Navigator.pop(modalContext);
                _deleteDocument(document);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? Colors.red
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
      ),
      onTap: onTap,
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
              await _performDelete(document);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(Document document) async {
    // Store the document for potential undo
    _pendingDelete = document;
    _isDeleting = false;

    // Remove from UI immediately (optimistic update)
    if (mounted) {
      setState(() {
        _documents = List<Document>.from(_documents)
          ..removeWhere((doc) => doc.id == document.id);
      });
    }

    // Show snackbar with undo option
    if (mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.surfaceDarkVariant,
                        AppColors.primaryDarkVariant.withOpacity(0.8),
                      ]
                    : [
                        AppColors.primary,
                        AppColors.cyan,
                        AppColors.accent,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? AppColors.primaryDarkVariant
                          : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Document "${document.title}" deleted',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      _undoDelete();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'UNDO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      );

      // Set a timer to actually delete after 5 seconds if not undone
      Future.delayed(const Duration(seconds: 5), () {
        if (_pendingDelete != null &&
            _pendingDelete!.id == document.id &&
            !_isDeleting &&
            mounted) {
          _confirmDelete(_pendingDelete!);
        }
      });
    }
  }

  void _undoDelete() {
    if (_pendingDelete != null && !_isDeleting && mounted) {
      // Hide the current delete snackbar immediately
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Restore the document to the list
      final docToRestore = _pendingDelete!;
      _pendingDelete = null;
      _isDeleting = false;

      setState(() {
        final mutableList = List<Document>.from(_documents);
        if (!mutableList.any((doc) => doc.id == docToRestore.id)) {
          mutableList.add(docToRestore);
          mutableList.sort((a, b) {
            if (_sortBy == 'date') {
              return b.dateCreated.compareTo(a.dateCreated);
            } else {
              return a.title.compareTo(b.title);
            }
          });
          _documents = mutableList;
        }
      });
      if (mounted) {
        // Show the restore snackbar immediately after hiding the delete one
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.undo, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Document "${docToRestore.title}" restored',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            margin: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Document document) async {
// Only delete if it's still pending (wasn't undone) and not already deleting
    if (_pendingDelete?.id != document.id || _isDeleting || !mounted) {
      return;
    }
    _isDeleting = true;

    try {
      await _documentService.deleteDocument(document.id);
      if (mounted) {
        setState(() {
          _pendingDelete = null;
          _isDeleting = false;
        });
      }
    } catch (e) {
      // If deletion fails, restore the document to the list
      if (mounted) {
        setState(() {
          final mutableList = List<Document>.from(_documents);
          if (!mutableList.any((doc) => doc.id == document.id)) {
            mutableList.add(document);
            // Re-sort
            mutableList.sort((a, b) {
              if (_sortBy == 'date') {
                return b.dateCreated.compareTo(a.dateCreated);
              } else {
                return a.title.compareTo(b.title);
              }
            });
            _documents = mutableList;
          }
          _pendingDelete = null;
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.error_outline,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to delete document: ${e.toString()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            margin: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
          ),
        );
      }
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = _getDocumentGradient();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : AppColors.primary.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Thumbnail/Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                        spreadRadius: 0.5,
                      ),
                      BoxShadow(
                        color: gradient.colors.last.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.white,
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDarkVariant
                                  : AppColors.blue50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(document.dateCreated),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDarkVariant
                                  : AppColors.cyanLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pages,
                                  size: 14,
                                  color: AppColors.cyan,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${document.pageCount} ${document.pageCount == 1 ? 'page' : 'pages'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.cyan,
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

                // Actions - Three dots icon
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDarkVariant
                        : AppColors.blue50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    onPressed: onTap,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Gradient _getDocumentGradient() {
// Create different gradients for variety while maintaining cohesion
    final gradients = [
      const LinearGradient(
        colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [AppColors.cyan, AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.indigo, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];
// Use document ID hash to consistently assign gradient
    final index = document.id.hashCode % gradients.length;
    return gradients[index.abs()];
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
