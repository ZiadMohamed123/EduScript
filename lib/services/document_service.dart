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
          return Document(
            id: doc['document_id'] as String? ?? '',
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

