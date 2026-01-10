// lib/services/quiz_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import '../models/question.dart';
import '../models/question_type.dart';

class QuizApiService {
  String get apiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (e) {
      // dotenv not initialized, return empty string
      return '';
    }
  }

  /// Base URL of your Node backend.
  ///
  /// If BACKEND_BASE_URL is set in .env, it will be used.
  /// Otherwise, automatically detects the platform:
  /// - Android Emulator: http://10.0.2.2:5000
  /// - Chrome/Web: http://localhost:5000
  /// - iOS Simulator: http://localhost:5000
  /// - Physical Device: You must set BACKEND_BASE_URL to your computer's IP
  String get backendBaseUrl {
    try {
      final envUrl = dotenv.env['BACKEND_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (e) {
      // dotenv not initialized, continue to auto-detection
    }

    // Auto-detect based on platform
    if (kIsWeb) {
      // Chrome/Web browser
      return 'http://localhost:5000';
    } else {
      // Mobile/Desktop platforms
      try {
        if (Platform.isAndroid) {
          // Android Emulator (10.0.2.2 maps to host's localhost)
          // For physical Android devices, you need to set BACKEND_BASE_URL to your computer's IP
          return 'http://10.0.2.2:5000';
        } else if (Platform.isIOS) {
          // iOS Simulator
          return 'http://localhost:5000';
        } else {
          // Desktop (Windows, Mac, Linux)
          return 'http://localhost:5000';
        }
      } catch (e) {
        return 'http://localhost:5000';
      }
    }
  }

  /// Optional: default JWT token for dev/testing.
  /// In production you should pass the token from your auth flow.
  String? get backendAuthToken {
    try {
      return dotenv.env['BACKEND_JWT'];
    } catch (e) {
      return null;
    }
  }

  String _getEnv(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (e) {
      // dotenv not initialized, return empty string
      return '';
    }
  }

  /// Build a dynamic prompt based on user's question type selection
  /// Build a MORE CONCISE dynamic prompt to avoid truncation
  String _buildDynamicPrompt({
    required String notes,
    required int totalQuestions,
    required int mcqCount,
    required int trueFalseCount,
    required int essayCount,
    required int shortAnswerCount,
  }) {
    // Build concise type breakdown
    final List<String> types = [];
    if (mcqCount > 0) types.add('$mcqCount MCQ');
    if (trueFalseCount > 0) types.add('$trueFalseCount T/F');
    if (shortAnswerCount > 0) types.add('$shortAnswerCount Short');
    if (essayCount > 0) types.add('$essayCount Essay');

    final distribution = types.join(', ');

    return '''Generate $totalQuestions questions ($distribution) from these notes as a JSON array.

JSON format:
[
  {"id": 1, "type": "mcq", "text": "question?", "options": ["A", "B", "C", "D"]},
  {"id": 2, "type": "trueFalse", "text": "statement", "options": []},
  ...
]

Rules:
- MCQ: 4 options, type="mcq"
- True/False: no options, type="trueFalse"  
- Short Answer: no options, type="shortAnswer"
- Essay: no options, type="essay"
- Return ONLY the JSON array, no markdown, no explanation

Notes:
$notes

JSON array:''';
  }

  Future<List<Question>> generateQuiz(
    String notes, {
    int? totalQuestions,
    int? mcqCount,
    int? trueFalseCount,
    int? essayCount,
    int? shortAnswerCount,
  }) async {
    // Validate API key before making request
    final key = apiKey;
    if (key.isEmpty) {
      throw Exception('API key is missing or empty!\n\n'
          'Please check:\n'
          '1. Create a .env file in the project root (same folder as pubspec.yaml)\n'
          '2. Add this line: GEMINI_API_KEY=your-api-key-here\n'
          '3. Make sure there are NO spaces around the = sign\n'
          '4. Restart the app completely (hot reload won\'t work)\n'
          '5. Run: flutter pub get\n\n'
          'Get your API key from: https://aistudio.google.com/app/apikey');
    }

    // Use defaults if not provided
    final total = totalQuestions ?? 5;
    final mcq = mcqCount ?? 3;
    final trueFalse = trueFalseCount ?? 1;
    final essay = essayCount ?? 1;
    final shortAnswer = shortAnswerCount ?? 0;

    // Build dynamic prompt based on user selection
    final prompt = _buildDynamicPrompt(
      notes: notes,
      totalQuestions: total,
      mcqCount: mcq,
      trueFalseCount: trueFalse,
      essayCount: essay,
      shortAnswerCount: shortAnswer,
    );

    // Use Google Gemini API endpoint
    final model = _getEnv('GEMINI_MODEL').isEmpty
        ? 'gemini-2.5-flash'
        : _getEnv('GEMINI_MODEL');
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key");

    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt,
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 8192,
        },
      }),
    );

    if (response.statusCode != 200) {
      // Parse error response for better error messages
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          final error = errorData['error'];
          final errorMessage = error['message'] as String? ?? 'Unknown error';
          final errorCode = error['code'] as int?;
          final errorStatus = error['status'] as String?;

          if (errorStatus == 'RESOURCE_EXHAUSTED' || errorCode == 429) {
            throw Exception('Gemini API Quota Exceeded\n\n'
                'Your API key has exceeded its usage quota.\n\n'
                'Troubleshooting steps:\n'
                '1. Check your quota and usage:\n'
                '   https://aistudio.google.com/app/apikey\n\n'
                '2. Verify your API key is valid\n\n'
                '3. Wait a few minutes and try again\n\n'
                '4. Check if you need to enable billing\n\n'
                'API Key used: ${key.substring(0, key.length > 12 ? 12 : key.length)}...\n'
                'Get a new key at: https://aistudio.google.com/app/apikey');
          } else if (errorStatus == 'UNAUTHENTICATED' || errorCode == 401) {
            throw Exception('Invalid API Key\n\n'
                'Your Gemini API key is invalid or has been revoked.\n\n'
                'Get a new key from:\n'
                'https://aistudio.google.com/app/apikey');
          } else if (errorStatus == 'RESOURCE_EXHAUSTED' || errorCode == 429) {
            throw Exception('Rate Limit Exceeded\n\n'
                'Too many requests. Please wait a moment and try again.');
          } else {
            throw Exception(
                'Gemini API Error: $errorMessage\nStatus: $errorStatus');
          }
        }
      } catch (e) {
        // If it's already our custom exception, rethrow it
        if (e.toString().contains('Gemini API')) {
          rethrow;
        }
        // If parsing fails, use raw response
      }
      throw Exception("API Error (${response.statusCode}): ${response.body}");
    }

    final data = jsonDecode(response.body);

    // Gemini API returns content in candidates[0].content.parts[0].text
    final content =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

    if (content == null || content.isEmpty) {
      throw Exception("No content in API response.");
    }

    // Extract JSON from the response (might have markdown code blocks)
    String jsonContent = content.trim();

    // Remove markdown code blocks
    if (jsonContent.startsWith('```json')) {
      jsonContent = jsonContent.substring(7);
    }
    if (jsonContent.startsWith('```')) {
      jsonContent = jsonContent.substring(3);
    }
    if (jsonContent.endsWith('```')) {
      jsonContent = jsonContent.substring(0, jsonContent.length - 3);
    }
    jsonContent = jsonContent.trim();

    // Debug: Print what we're trying to parse
    print('🔍 Raw content length: ${content.length}');
    print('🔍 Cleaned JSON length: ${jsonContent.length}');
    print(
        '🔍 First 200 chars: ${jsonContent.length > 200 ? jsonContent.substring(0, 200) : jsonContent}...');

    // Check if content is empty
    if (jsonContent.isEmpty) {
      throw Exception("Gemini returned empty response. This might be due to:\n"
          "1. Content safety filters\n"
          "2. The notes being too short or unclear\n"
          "3. API quota exceeded\n\n"
          "Try with different notes or check your API usage.");
    }

    // Try to parse as JSON
    dynamic parsedData;
    try {
      parsedData = jsonDecode(jsonContent);
    } catch (e) {
      // If JSON parsing fails, try to extract JSON array from text
      print('❌ JSON parse error: $e');
      print('🔍 Attempting to extract JSON array from text...');

      // Try to find JSON array in the text
      final jsonArrayMatch =
          RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(jsonContent);
      if (jsonArrayMatch != null) {
        try {
          jsonContent = jsonArrayMatch.group(0)!;
          parsedData = jsonDecode(jsonContent);
          print('✅ Successfully extracted JSON array!');
        } catch (e2) {
          throw Exception("Failed to parse Gemini response as JSON.\n\n"
              "Raw response:\n${jsonContent.length > 500 ? '${jsonContent.substring(0, 500)}...' : jsonContent}\n\n"
              "Error: $e2");
        }
      } else {
        throw Exception("Gemini did not return valid JSON.\n\n"
            "Raw response:\n${jsonContent.length > 500 ? '${jsonContent.substring(0, 500)}...' : jsonContent}\n\n"
            "Error: $e\n\n"
            "Try:\n"
            "1. Use simpler notes\n"
            "2. Reduce the number of questions\n"
            "3. Try again in a few minutes");
      }
    }

    // Parse the JSON into questions
    List<dynamic> parsedJson;

    if (parsedData is Map && parsedData.containsKey('questions')) {
      parsedJson = List<dynamic>.from(parsedData['questions']);
    } else if (parsedData is List) {
      parsedJson = parsedData;
    } else if (parsedData is Map) {
      // If it's a single object, wrap it in a list
      parsedJson = [parsedData];
    } else {
      throw Exception("Unexpected response format from Gemini API.\n"
          "Expected: JSON array of questions\n"
          "Got: ${parsedData.runtimeType}");
    }

    print('✅ Successfully parsed ${parsedJson.length} questions');

    // Validate and convert to Question objects
    final questions = <Question>[];
    for (var i = 0; i < parsedJson.length; i++) {
      try {
        final q = parsedJson[i];

        // Validate required fields
        if (q['id'] == null || q['type'] == null || q['text'] == null) {
          print('⚠️ Skipping question $i: Missing required fields');
          continue;
        }

        final question = Question(
          id: q['id'] is int
              ? q['id']
              : int.tryParse(q['id'].toString()) ?? i + 1,
          type: QuestionType.values.firstWhere(
            (t) => t.toString().split('.').last == q['type'],
            orElse: () => QuestionType.mcq,
          ),
          text: q['text'],
          options: List<String>.from(q['options'] ?? []),
        );

        questions.add(question);
      } catch (e) {
        print('⚠️ Error parsing question $i: $e');
        continue;
      }
    }

    if (questions.isEmpty) {
      throw Exception("No valid questions were generated.\n\n"
          "The AI returned ${parsedJson.length} question(s) but none could be parsed.\n\n"
          "Try:\n"
          "1. Simplify your notes\n"
          "2. Use fewer questions\n"
          "3. Try different question types");
    }

    print('✅ Successfully created ${questions.length} Question objects');
    return questions;
  }

  /// Save a generated quiz to the backend (Supabase via Node API).
  ///
  /// Expects your backend to expose POST /quiz/add with the body:
  /// {
  ///   "documentID": "...",
  ///   "name": "Quiz title",
  ///   "questions": [
  ///     { "text": "...", "answers": [ { "text": "...", "isCorrect": false } ] }
  ///   ]
  /// }
  ///
  ///
  /// Save quiz attempt with results
  /// Save quiz attempt with results

// ============================================
// ADD THIS METHOD TO quiz_api_service.dart
// Add it right before the closing brace of the class
// ============================================

  Future<Map<String, dynamic>> saveQuizToDatabase({
    required String documentId,
    required String name,
    required List<Question> questions,
    required Map<String, dynamic> quizResults, // ← ADDED
    String? authToken,
  }) async {
    final baseUrl = backendBaseUrl;
    if (baseUrl.isEmpty) {
      throw Exception('BACKEND_BASE_URL is not set in .env');
    }

    final token = authToken ?? backendAuthToken;
    if (token == null || token.isEmpty) {
      throw Exception('Missing JWT token');
    }

    final url = Uri.parse('$baseUrl/quiz/add');

    print('💾 Saving quiz with user answers');

    // Get feedback list
    final feedbackList = quizResults['feedback'] as List<dynamic>? ?? [];

    // Build questions WITH user answers
    final questionsPayload = questions.asMap().entries.map((entry) {
      final index = entry.key;
      final q = entry.value;

      // Find feedback
      final feedback = feedbackList.firstWhere(
        (f) => f['questionId'] == q.id,
        orElse: () => {
          'correctAnswer': '',
          'userAnswer': '',
          'isCorrect': false,
          'feedback': ''
        },
      );

      final userAnswer = q.userAnswer ?? '';
      final correctAnswer = feedback['correctAnswer'] as String? ?? '';

      List<Map<String, dynamic>>? answers;

      if (q.type == QuestionType.mcq && q.options.isNotEmpty) {
        answers = q.options.map((opt) {
          return {
            'text': opt,
            'isCorrect': (opt == correctAnswer),
            'userSelected': (opt == userAnswer), // ← Mark what user selected
          };
        }).toList();
      } else if (q.type == QuestionType.trueFalse) {
        answers = ['True', 'False'].map((opt) {
          return {
            'text': opt,
            'isCorrect': (opt == correctAnswer),
            'userSelected': (opt == userAnswer),
          };
        }).toList();
      }

      return {
        'text': q.text,
        if (answers != null) 'answers': answers,
      };
    }).toList();

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'documentID': documentId,
              'name': name,
              'questions': questionsPayload,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 201) {
        throw Exception('Failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('   ✅ Saved!');
      return data;
    } catch (e) {
      print('   ❌ Error: $e');
      rethrow;
    }
  }

  /// Get all saved quizzes for the current user
  Future<List<Map<String, dynamic>>> getAllQuizzes(String authToken) async {
    final baseUrl = backendBaseUrl;
    if (baseUrl.isEmpty) {
      throw Exception(
        'BACKEND_BASE_URL is not set in .env.\n'
        'Add e.g. BACKEND_BASE_URL=http://192.168.1.18:5000 to your .env file.',
      );
    }

    if (authToken.isEmpty) {
      throw Exception('Missing authentication token');
    }

    final url = Uri.parse('$baseUrl/quiz/all');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        const Duration(seconds: 30), // Increased timeout for slow connections
        onTimeout: () {
          throw Exception(
              'Connection timeout. Is your backend server running?\n\n'
              'Make sure your backend is running: cd backend && npm start');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final quizzes = data['quizzes'] as List<dynamic>? ?? [];
        return quizzes.map((q) => q as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to fetch quizzes: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception('Error fetching quizzes: $e');
    }
  }

  /// Get details for a specific quiz including all questions
  Future<Map<String, dynamic>> getQuizDetails(
      String quizId, String authToken) async {
    final baseUrl = backendBaseUrl;
    if (baseUrl.isEmpty) {
      throw Exception(
        'BACKEND_BASE_URL is not set in .env.\n'
        'Add e.g. BACKEND_BASE_URL=http://localhost:5000 to your .env file.',
      );
    }

    if (authToken.isEmpty) {
      throw Exception('Missing authentication token');
    }

    final url = Uri.parse('$baseUrl/quiz/$quizId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Is your backend server running?\n\n'
              'Make sure your backend is running: cd backend && npm start');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['quiz'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Quiz not found');
      } else {
        throw Exception('Failed to fetch quiz details: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception('Error fetching quiz details: $e');
    }
  }

  /// Delete a saved quiz
  Future<void> deleteQuiz(String quizId, String authToken) async {
    final baseUrl = backendBaseUrl;
    if (baseUrl.isEmpty) {
      throw Exception(
        'BACKEND_BASE_URL is not set in .env.\n'
        'Add e.g. BACKEND_BASE_URL=http://localhost:5000 to your .env file.',
      );
    }

    if (authToken.isEmpty) {
      throw Exception('Missing authentication token');
    }

    final url = Uri.parse('$baseUrl/quiz/$quizId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Is your backend server running?\n\n'
              'Make sure your backend is running: cd backend && npm start');
        },
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Quiz not found');
      } else {
        throw Exception('Failed to delete quiz: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception('Error deleting quiz: $e');
    }
  }

  Future<Map<String, dynamic>> submitQuiz(List<Question> questions) async {
    // Validate API key before making request
    final key = apiKey;
    if (key.isEmpty) {
      throw Exception('API key is missing or empty!\n\n'
          'Please check:\n'
          '1. Create a .env file in the project root (same folder as pubspec.yaml)\n'
          '2. Add this line: GEMINI_API_KEY=your-api-key-here\n'
          '3. Make sure there are NO spaces around the = sign\n'
          '4. Restart the app completely (hot reload won\'t work)\n'
          '5. Run: flutter pub get\n\n'
          'Get your API key from: https://aistudio.google.com/app/apikey');
    }

    // Use Google Gemini API endpoint
    final model = _getEnv('GEMINI_MODEL').isEmpty
        ? 'gemini-2.5-flash'
        : _getEnv('GEMINI_MODEL');
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key");

    // Build questions JSON for the prompt
    final questionsJson = questions.map((q) {
      return {
        'id': q.id,
        'type': q.type.toString().split('.').last,
        'text': q.text,
        'options': q.options,
        'userAnswer': q.userAnswer ?? '',
      };
    }).toList();

    final prompt =
        '''You are a quiz grader. Evaluate the following quiz answers and provide a score.

For each question:
- MCQ and True/False: Check if the user's answer matches the correct answer (case-insensitive)
- Short Answer and Essay: Evaluate based on correctness and completeness (be lenient but accurate)

Return a JSON object with this exact structure:
{
  "score": number (0-100),
  "totalQuestions": number,
  "correctAnswers": number,
  "feedback": [
    {
      "questionId": number,
      "isCorrect": boolean,
      "correctAnswer": string (the correct answer),
      "feedback": string (brief feedback for the answer)
    }
  ]
}

Questions and Answers:
${jsonEncode(questionsJson)}

Return ONLY the JSON object, no markdown code blocks or explanations.''';

    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt,
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.3,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 8192,
        },
      }),
    );

    if (response.statusCode != 200) {
      // Parse error response for better error messages
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          final error = errorData['error'];
          final errorMessage = error['message'] as String? ?? 'Unknown error';
          final errorCode = error['code'] as int?;
          final errorStatus = error['status'] as String?;

          if (errorStatus == 'RESOURCE_EXHAUSTED' || errorCode == 429) {
            throw Exception('Gemini API Quota Exceeded\n\n'
                'Your API key has exceeded its usage quota.\n\n'
                'Troubleshooting steps:\n'
                '1. Check your quota and usage:\n'
                '   https://aistudio.google.com/app/apikey\n\n'
                '2. Verify your API key is valid\n\n'
                '3. Wait a few minutes and try again\n\n'
                '4. Check if you need to enable billing\n\n'
                'API Key used: ${key.substring(0, key.length > 12 ? 12 : key.length)}...\n'
                'Get a new key at: https://aistudio.google.com/app/apikey');
          } else if (errorStatus == 'UNAUTHENTICATED' || errorCode == 401) {
            throw Exception('Invalid API Key\n\n'
                'Your Gemini API key is invalid or has been revoked.\n\n'
                'Get a new key from:\n'
                'https://aistudio.google.com/app/apikey');
          } else {
            throw Exception(
                'Gemini API Error: $errorMessage\nStatus: $errorStatus');
          }
        }
      } catch (e) {
        // If it's already our custom exception, rethrow it
        if (e.toString().contains('Gemini API')) {
          rethrow;
        }
      }
      throw Exception("API Error (${response.statusCode}): ${response.body}");
    }

    final data = jsonDecode(response.body);

    // Gemini API returns content in candidates[0].content.parts[0].text
    final content =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

    if (content == null || content.isEmpty) {
      throw Exception("No content in API response.");
    }

    // Extract JSON from the response (might have markdown code blocks)
    String jsonContent = content.trim();
    if (jsonContent.startsWith('```json')) {
      jsonContent = jsonContent.substring(7);
    }
    if (jsonContent.startsWith('```')) {
      jsonContent = jsonContent.substring(3);
    }
    if (jsonContent.endsWith('```')) {
      jsonContent = jsonContent.substring(0, jsonContent.length - 3);
    }
    jsonContent = jsonContent.trim();

    // Parse the result
    final result = jsonDecode(jsonContent) as Map<String, dynamic>;

    return {
      'score': result['score'] as int? ?? 0,
      'totalQuestions': result['totalQuestions'] as int? ?? questions.length,
      'correctAnswers': result['correctAnswers'] as int? ?? 0,
      'feedback': result['feedback'] as List<dynamic>? ?? [],
    };
  }

  /// Get quizzes by document ID
  Future<List<Map<String, dynamic>>> getQuizzesByDocument(
      String documentId, String authToken) async {
    final baseUrl = backendBaseUrl;
    if (baseUrl.isEmpty) {
      throw Exception(
        'BACKEND_BASE_URL is not set in .env.\n'
        'Add e.g. BACKEND_BASE_URL=http://localhost:5000 to your .env file.',
      );
    }

    if (authToken.isEmpty) {
      throw Exception('Missing authentication token');
    }

    final url = Uri.parse('$baseUrl/quiz/document/$documentId');

    print('🌐 Making request to: $url');
    print(
        '🔑 Token (first 20 chars): ${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}...');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Is your backend server running?\n\n'
              'Make sure your backend is running: cd backend && npm start');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final quizzes = data['quizzes'] as List<dynamic>? ?? [];
        return quizzes.map((q) => q as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        // No quizzes found for this document - return empty list
        return [];
      } else if (response.statusCode == 500) {
        throw Exception('Server error: ${response.body}');
      } else {
        throw Exception(
            'Failed to fetch quizzes: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error in getQuizzesByDocument API call: $e');
      if (e.toString().contains('timeout') ||
          e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception('Error fetching quizzes: $e');
    }
  }
}
