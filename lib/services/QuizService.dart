import 'dart:convert';
import '../services/quiz_api_service.dart';
import '../services/auth_service.dart';

/// Saved Quiz Model
class SavedQuiz {
  final String id;
  final String name;
  final String documentId;
  final DateTime dateCreated;
  final int questionCount;
  final String? documentName;

  SavedQuiz({
    required this.id,
    required this.name,
    required this.documentId,
    required this.dateCreated,
    required this.questionCount,
    this.documentName,
  });

  factory SavedQuiz.fromJson(Map<String, dynamic> json) {
    // Parse questions to get count
    final questions = json['questions'] as List<dynamic>? ?? [];
    
    return SavedQuiz(
      id: json['quiz_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Untitled Quiz',
      documentId: json['document_id']?.toString() ?? '',
      dateCreated: _parseDate(json['created_at'] as String?),
      questionCount: questions.length,
      documentName: json['document_name'] as String?,
    );
  }

  static DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }
}

/// Quiz Service
/// Manages quiz storage and retrieval from backend API
class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final QuizApiService _api = QuizApiService();
  final AuthService _authService = AuthService();

  List<SavedQuiz> _cachedQuizzes = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get all saved quizzes from API
  Future<List<SavedQuiz>> getAllQuizzes() async {
    // Return cached data if still fresh
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _cachedQuizzes.isNotEmpty) {
      return List.unmodifiable(_cachedQuizzes);
    }

    try {
      final authToken = await _authService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      final quizzesList = await _api.getAllQuizzes(authToken);

      _cachedQuizzes = quizzesList.map((quiz) {
        return SavedQuiz.fromJson(quiz);
      }).toList();

      _lastFetchTime = DateTime.now();
      return List.unmodifiable(_cachedQuizzes);
    } catch (e) {
      // Return cached data if available, even if stale
      if (_cachedQuizzes.isNotEmpty) {
        return List.unmodifiable(_cachedQuizzes);
      }
      rethrow;
    }
  }

  /// NEW: Get quizzes by document ID
  Future<List<SavedQuiz>> getQuizzesByDocument(String documentId) async {
    try {
      final authToken = await _authService.getAuthToken();
      print('🔑 Auth token in getQuizzesByDocument: ${authToken?.substring(0, 20)}...');
      
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      final quizzesList = await _api.getQuizzesByDocument(documentId, authToken);

      return quizzesList.map((quiz) {
        return SavedQuiz.fromJson(quiz);
      }).toList();
    } catch (e) {
      print('❌ Error in getQuizzesByDocument: $e');
      rethrow;
    }
  }

  /// Get the last N quizzes sorted by date (most recent first)
  Future<List<SavedQuiz>> getRecentQuizzes({int limit = 10}) async {
    final allQuizzes = await getAllQuizzes();
    // Sort by date descending
    final sortedQuizzes = List<SavedQuiz>.from(allQuizzes);
    sortedQuizzes.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    return sortedQuizzes.take(limit).toList();
  }

  /// Get a quiz by ID
  Future<SavedQuiz?> getQuizById(String id) async {
    final quizzes = await getAllQuizzes();
    try {
      return quizzes.firstWhere((quiz) => quiz.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get quiz details with questions
  Future<Map<String, dynamic>> getQuizDetails(String quizId) async {
    try {
      final authToken = await _authService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      return await _api.getQuizDetails(quizId, authToken);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear cache (call this after adding/deleting quizzes)
  void clearCache() {
    _cachedQuizzes.clear();
    _lastFetchTime = null;
  }

  /// Delete a quiz from API
  Future<void> deleteQuiz(String id) async {
    try {
      final authToken = await _authService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      await _api.deleteQuiz(id, authToken);
      
      // Clear cache to force refresh on next fetch
      clearCache();
    } catch (e) {
      rethrow;
    }
  }
}