import 'dart:convert';
import '../screens/documents_list_page.dart';
import '../utils/http_client.dart';

/// Document Service
/// Manages document storage and retrieval from backend API
class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  List<Document> _cachedDocuments = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cache for extracted text to avoid multiple API calls
  final Map<String, String> _extractedTextCache = {};

  /// Get all documents from API
  Future<List<Document>> getAllDocuments() async {
    // Return cached data if still fresh
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _cachedDocuments.isNotEmpty) {
      return List.unmodifiable(_cachedDocuments);
    }

    try {
      final response = await HttpClient.get('/document/allDocsMetaData');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documentsList = data['documents'] as List<dynamic>? ?? [];

        _cachedDocuments = documentsList.map((doc) {
          // API returns upload_date from the query, but may also have created_at
          final dateString = doc['upload_date'] as String? ?? 
                            doc['created_at'] as String?;
          
          // Cache the extracted text if available
          final docId = doc['document_id'] as String? ?? '';
          final extractedText = doc['extracted_text'] as String?;
          if (docId.isNotEmpty && extractedText != null && extractedText.isNotEmpty) {
            _extractedTextCache[docId] = extractedText;
          }
          
          return Document(
            id: docId,
            title: doc['name'] as String? ?? 'Untitled Document',
            dateCreated: _parseDate(dateString),
            pageCount: (doc['no_of_pages'] as num?)?.toInt() ?? 1,
            thumbnailPath: null, // Not provided by API
          );
        }).toList();

        _lastFetchTime = DateTime.now();
        return List.unmodifiable(_cachedDocuments);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to fetch documents: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached data if available, even if stale
      if (_cachedDocuments.isNotEmpty) {
        return List.unmodifiable(_cachedDocuments);
      }
      rethrow;
    }
  }

  /// Get the last N documents sorted by date (most recent first)
  Future<List<Document>> getRecentDocuments({int limit = 10}) async {
    final allDocs = await getAllDocuments();
    // Documents are already sorted by upload_date descending from API
    return allDocs.take(limit).toList();
  }

  /// Get a document by ID
  Future<Document?> getDocumentById(String id) async {
    final documents = await getAllDocuments();
    try {
      return documents.firstWhere((doc) => doc.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get extracted text for a specific document
  /// This method fetches all documents metadata which includes extracted_text
  /// and caches it for future use
  Future<String?> getExtractedText(String documentId) async {
    try {
      // Check if we have it in cache first
      if (_extractedTextCache.containsKey(documentId)) {
        final cachedText = _extractedTextCache[documentId];
        if (cachedText != null && cachedText.trim().isNotEmpty) {
          return cachedText;
        }
      }

      // Fetch all documents metadata (which includes extracted_text)
      final response = await HttpClient.get('/document/allDocsMetaData');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documentsList = data['documents'] as List<dynamic>? ?? [];

        // Find the specific document and get its extracted text
        for (var doc in documentsList) {
          final docId = doc['document_id'] as String?;
          final extractedText = doc['extracted_text'] as String?;
          
          // Cache all extracted texts while we're at it
          if (docId != null && extractedText != null && extractedText.isNotEmpty) {
            _extractedTextCache[docId] = extractedText;
          }
        }

        // Return the requested document's extracted text
        if (_extractedTextCache.containsKey(documentId)) {
          final text = _extractedTextCache[documentId];
          if (text != null && text.trim().isNotEmpty) {
            return text;
          }
        }

        // Document found but no extracted text available
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to fetch document data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching extracted text: $e');
    }
  }

  /// Parse date string from API
  DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }
    try {
      // Try parsing ISO 8601 format
      return DateTime.parse(dateString);
    } catch (e) {
      // Fallback to current date if parsing fails
      return DateTime.now();
    }
  }

  /// Clear cache (call this after adding/deleting documents)
  void clearCache() {
    _cachedDocuments.clear();
    _extractedTextCache.clear();
    _lastFetchTime = null;
  }

  /// Delete a document from API
  Future<void> deleteDocument(String id) async {
    try {
      final response = await HttpClient.delete('/document/$id');

      if (response.statusCode == 200) {
        // Clear cache to force refresh on next fetch
        clearCache();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Document not found');
      } else {
        throw Exception('Failed to delete document: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}