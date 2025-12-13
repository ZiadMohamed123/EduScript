import '../screens/documents_list_page.dart';

/// Document Service
/// Manages document storage and retrieval
/// In a real app, this would use a database or backend API
class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  // Mock data - in a real app, this would come from a database
  List<Document> _documents = [
    Document(
      id: '1',
      title: 'Math Lecture Notes',
      dateCreated: DateTime.now().subtract(const Duration(days: 2)),
      pageCount: 5,
    ),
    Document(
      id: '2',
      title: 'Physics Chapter 3',
      dateCreated: DateTime.now().subtract(const Duration(days: 5)),
      pageCount: 3,
    ),
    Document(
      id: '3',
      title: 'Chemistry Lab Report',
      dateCreated: DateTime.now().subtract(const Duration(days: 7)),
      pageCount: 8,
    ),
  ];

  /// Get all documents
  List<Document> getAllDocuments() {
    return List.unmodifiable(_documents);
  }

  /// Get a document by ID
  Document? getDocumentById(String id) {
    try {
      return _documents.firstWhere((doc) => doc.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new document
  void addDocument(Document document) {
    _documents.add(document);
  }

  /// Delete a document
  void deleteDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
  }

  /// Update a document
  void updateDocument(Document document) {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      _documents[index] = document;
    }
  }
}

