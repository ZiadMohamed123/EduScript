import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  // Cache for document summaries (documentId -> summary)
  final Map<String, String?> _summaryCache = {};
  // Cache for document extracted_text (documentId -> extracted_text)
  final Map<String, String?> _extractedTextCache = {};
  DateTime? _lastSummaryFetchTime;

  /// Get all documents from API
  Future<List<Document>> getAllDocuments() async {
    // Return cached data if still fresh
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _cachedDocuments.isNotEmpty) {
      return List.unmodifiable(_cachedDocuments);
    }

    try {
      // Backend automatically filters documents by user_id from JWT token
      final response = await HttpClient.get('/document/allDocsMetaData');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documentsList = data['documents'] as List<dynamic>? ?? [];

        // Backend already filters by user, but we validate here as well
        // All documents returned should belong to the current logged-in user
        _cachedDocuments = documentsList.map((doc) {
          final dateString =
              doc['upload_date'] as String? ?? doc['created_at'] as String?;
          return Document(
            id: doc['document_id'] as String? ?? '',
            title: doc['name'] as String? ?? 'Untitled Document',
            dateCreated: _parseDate(dateString),
            pageCount: (doc['no_of_pages'] as num?)?.toInt() ?? 1,
          );
        }).toList();

        // Clear cache on logout to prevent showing other users' documents
        // This is handled by clearCache() which should be called on logout

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

  /// Parse date string from API
  DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Clear cache (call this after adding/deleting documents)
  void clearCache() {
    _cachedDocuments.clear();
    _lastFetchTime = null;
    _summaryCache.clear();
    _extractedTextCache.clear();
    _lastSummaryFetchTime = null;
  }

  /// Update summary in cache (call after updating summary)
  void updateSummaryCache(String id, String? summary) {
    _summaryCache[id] = summary;
  }

  /// Update extracted_text in cache
  void updateExtractedTextCache(String id, String? extractedText) {
    _extractedTextCache[id] = extractedText;
  }

  /// Get document data (summary and extracted_text) from API
  /// According to API docs: GET /document/allDocsMetaData returns both fields
  /// Uses cache if available to avoid unnecessary API calls
  Future<Map<String, String?>> getDocumentData(String id) async {
    try {
      // Check cache first (very fast) - both summary and extracted_text
      if (_summaryCache.containsKey(id) &&
          _extractedTextCache.containsKey(id)) {
        final cachedSummary = _summaryCache[id];
        final cachedExtractedText = _extractedTextCache[id];

        // If cache is fresh, return cached values
        if (_lastSummaryFetchTime != null &&
            DateTime.now().difference(_lastSummaryFetchTime!) <
                _cacheDuration) {
          return {
            'summary':
                (cachedSummary != null && cachedSummary.trim().isNotEmpty)
                    ? cachedSummary
                    : null,
            'extracted_text': (cachedExtractedText != null &&
                    cachedExtractedText.trim().isNotEmpty)
                ? cachedExtractedText
                : null,
          };
        }
      }

      // Cache expired or not found, fetch from API
      // According to API docs: GET /document/allDocsMetaData returns documents with summary and extracted_text
      final response = await HttpClient.get('/document/allDocsMetaData');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documentsList = data['documents'] as List<dynamic>? ?? [];

        // Update both caches for all documents
        _summaryCache.clear();
        _extractedTextCache.clear();
        String? foundSummary;
        String? foundExtractedText;

        for (final doc in documentsList) {
          final docId = doc['document_id'] as String? ?? '';
          final summary = doc['summary'] as String?;
          // Try both snake_case and camelCase for extracted_text
          final extractedText = doc['extracted_text'] as String? ??
              doc['extractedText'] as String?;

          // Cache summary
          _summaryCache[docId] =
              (summary != null && summary.trim().isNotEmpty) ? summary : null;

          // Cache extracted_text
          _extractedTextCache[docId] =
              (extractedText != null && extractedText.trim().isNotEmpty)
                  ? extractedText
                  : null;

          if (docId == id) {
            foundSummary = _summaryCache[docId];
            foundExtractedText = _extractedTextCache[docId];

            // Debug: Print what we actually received
            debugPrint(
                'Document $id - Summary: ${foundSummary != null ? "exists (${foundSummary.length} chars)" : "null"}');
            debugPrint(
                'Document $id - ExtractedText: ${foundExtractedText != null ? "exists (${foundExtractedText.length} chars)" : "null"}');
            debugPrint('Document $id - Available keys: ${doc.keys.toList()}');
          }
        }

        _lastSummaryFetchTime = DateTime.now();
        return {
          'summary': foundSummary,
          'extracted_text': foundExtractedText,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to fetch documents: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get document summary from the documents list
  /// Uses cache if available to avoid unnecessary API calls
  Future<String?> getDocumentSummary(String id) async {
    final data = await getDocumentData(id);
    return data['summary'];
  }

  /// Update document summary
  Future<void> updateDocumentSummary(String id, String summary) async {
    try {
      // Body should include summary field
      final response = await HttpClient.put(
        '/document/edit/$id',
        body: {
          'summary': summary,
        },
      );

      if (response.statusCode == 200) {
        updateSummaryCache(id, summary);
        _cachedDocuments.clear();
        _lastFetchTime = null;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Document not found');
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        final errorMessage = errorData?['message'] as String?;
        throw Exception(
            errorMessage ?? 'Failed to update summary: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a document from API
  /// This deletes the document from the database and the file from storage
  Future<void> deleteDocument(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Document ID cannot be empty');
      }
      debugPrint('Deleting document with ID: $id');
      final response = await HttpClient.delete('/document/delete/$id');

      debugPrint('Delete response status: ${response.statusCode}');
      debugPrint('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Document deleted successfully from database');
        clearCache();
        _cachedDocuments.removeWhere((doc) => doc.id == id);
        _summaryCache.remove(id);
        _extractedTextCache.remove(id);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Document not found or access denied');
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        final errorMessage = errorData?['message'] as String?;
        debugPrint(
            'Delete failed with status ${response.statusCode}: $errorMessage');
        if (response.statusCode == 500) {
          throw Exception('Server error while deleting document. '
              'The document file may be missing or there was a database error.');
        }
        throw Exception(errorMessage ?? 'Failed to delete document');
      }
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }
}
