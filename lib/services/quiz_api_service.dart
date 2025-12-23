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
  /// - Android Emulator: http://10.0.2.2:5000
  /// - Chrome/Web: http://localhost:5000
  /// - iOS Simulator: http://localhost:5000
  /// - Physical Device: You must set BACKEND_BASE_URL to your computer's IP
  String get backendBaseUrl {
    try {
      final envUrl = dotenv.env['BACKEND_BASE_URL'];
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

  Future<List<Question>> generateQuiz(String notes) async {
    // Validate API key before making request
    final key = apiKey;
    if (key.isEmpty) {
      throw Exception(
        'API key is missing or empty!\n\n'
        'Please check:\n'
        '1. Create a .env file in the project root (same folder as pubspec.yaml)\n'
        '2. Add this line: GEMINI_API_KEY=your-api-key-here\n'
        '3. Make sure there are NO spaces around the = sign\n'
        '4. Restart the app completely (hot reload won\'t work)\n'
        '5. Run: flutter pub get\n\n'
        'Get your API key from: https://aistudio.google.com/app/apikey'
      );
    }

    // Use Google Gemini API endpoint
    final model = _getEnv('GEMINI_MODEL').isEmpty ? 'gemini-2.5-flash' : _getEnv('GEMINI_MODEL');
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key"
    );

    final prompt = '''Generate exactly 5 questions from the following notes in **valid JSON array**.

Each question item must include:
{
  "id": number,
  "type": "mcq" | "trueFalse" | "essay" | "shortAnswer",
  "text": string,
  "options": [] or ["A", "B", ...]
}

If type is essay or shortAnswer → options must be [].

Notes:
$notes

Return ONLY the JSON array, no other text. Do not include markdown code blocks or any explanation.''';

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
          "maxOutputTokens": 2048,
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
            throw Exception(
              'Gemini API Quota Exceeded\n\n'
              'Your API key has exceeded its usage quota.\n\n'
              'Troubleshooting steps:\n'
              '1. Check your quota and usage:\n'
              '   https://aistudio.google.com/app/apikey\n\n'
              '2. Verify your API key is valid\n\n'
              '3. Wait a few minutes and try again\n\n'
              '4. Check if you need to enable billing\n\n'
              'API Key used: ${key.substring(0, key.length > 12 ? 12 : key.length)}...\n'
              'Get a new key at: https://aistudio.google.com/app/apikey'
            );
          } else if (errorStatus == 'UNAUTHENTICATED' || errorCode == 401) {
            throw Exception(
              'Invalid API Key\n\n'
              'Your Gemini API key is invalid or has been revoked.\n\n'
              'Get a new key from:\n'
              'https://aistudio.google.com/app/apikey'
            );
          } else if (errorStatus == 'RESOURCE_EXHAUSTED' || errorCode == 429) {
            throw Exception(
              'Rate Limit Exceeded\n\n'
              'Too many requests. Please wait a moment and try again.'
            );
          } else {
            throw Exception('Gemini API Error: $errorMessage\nStatus: $errorStatus');
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
    final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

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

    // Try to parse as JSON object first (in case it's wrapped in an object)
    dynamic parsedData = jsonDecode(jsonContent);
    List<dynamic> parsedJson;
    
    if (parsedData is Map && parsedData.containsKey('questions')) {
      parsedJson = List<dynamic>.from(parsedData['questions']);
    } else if (parsedData is List) {
      parsedJson = parsedData;
    } else if (parsedData is Map) {
      // If it's a single object, wrap it in a list
      parsedJson = [parsedData];
    } else {
      throw Exception("Unexpected response format from API.");
    }

    return parsedJson.map((q) {
      return Question(
        id: q['id'],
        type: QuestionType.values.firstWhere(
          (t) => t.toString().split('.').last == q['type'],
        ),
        text: q['text'],
        options: List<String>.from(q['options'] ?? []),
      );
    }).toList();
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
  Future<Map<String, dynamic>> saveQuizToDatabase({
    required String documentId,
    required String name,
    required List<Question> questions,
    String? authToken,
  }) async {
    final baseUrl = backendBaseUrl;
    if (baseUrl.isEmpty) {
      throw Exception(
        'BACKEND_BASE_URL is not set in .env.\n'
        'Add e.g. BACKEND_BASE_URL=http://localhost:5000 to your .env file.',
      );
    }

    final token = authToken ?? backendAuthToken;
    if (token == null || token.isEmpty) {
      throw Exception(
        'Missing JWT token for backend.\n'
        'Either pass authToken to saveQuizToDatabase or set BACKEND_JWT in .env.\n\n'
        'To get a token:\n'
        '1. Start your backend: cd backend && npm start\n'
        '2. POST to http://localhost:5000/auth/login with email/password\n'
        '3. Copy the token from the response\n'
        '4. Add BACKEND_JWT=your-token-here to .env',
      );
    }

    final url = Uri.parse('$baseUrl/quiz/add');
    
    // Debug info (will be shown in error if connection fails)
    final debugInfo = '''
Attempting to connect to: $baseUrl
Full URL: $url
Platform: ${kIsWeb ? 'Web/Chrome' : Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Desktop'}
''';

    // Map Flutter Question model to backend Question/Answer shape
    final questionsPayload = questions.map((q) {
      List<Map<String, dynamic>>? answers;

      if (q.type == QuestionType.mcq && q.options.isNotEmpty) {
        answers = q.options
            .map((opt) => {
                  'text': opt,
                  // We don't know the correct answer here, so default to false.
                  'isCorrect': false,
                })
            .toList();
      } else if (q.type == QuestionType.trueFalse) {
        answers = [
          {'text': 'True', 'isCorrect': false},
          {'text': 'False', 'isCorrect': false},
        ];
      } else if (q.options.isNotEmpty) {
        // For other types with options, just store them as non-correct answers.
        answers = q.options
            .map((opt) => {
                  'text': opt,
                  'isCorrect': false,
                })
            .toList();
      }

      final map = <String, dynamic>{
        'text': q.text,
      };
      if (answers != null && answers.isNotEmpty) {
        map['answers'] = answers;
      }
      return map;
    }).toList();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'documentID': documentId,
          'name': name,
          'questions': questionsPayload,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Is your backend server running?\n\n'
            'Troubleshooting:\n'
            '1. Make sure your backend is running: cd backend && npm start\n'
            '2. Check BACKEND_BASE_URL in .env:\n'
            '   - Android Emulator: http://10.0.2.2:5000\n'
            '   - iOS Simulator: http://localhost:5000\n'
            '   - Physical Device: http://YOUR_COMPUTER_IP:5000\n'
            '3. Verify the backend is accessible at: $baseUrl'
          );
        },
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to save quiz (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: ${e.message}\n\n'
        '$debugInfo'
        'Troubleshooting:\n'
        '1. Is your backend server running?\n'
        '   → Open terminal: cd backend && npm start\n'
        '   → You should see: "Server running on port: 5000"\n\n'
        '2. Test the backend URL:\n'
        '   → Open in browser: $baseUrl/auth/login\n'
        '   → If it works, backend is running\n\n'
        '3. Check BACKEND_BASE_URL in .env:\n'
        '   - Android Emulator: http://10.0.2.2:5000\n'
        '   - Chrome/Web: http://localhost:5000\n'
        '   - iOS Simulator: http://localhost:5000\n'
        '   - Physical Device: http://YOUR_COMPUTER_IP:5000\n\n'
        '4. Current detected URL: $baseUrl\n\n'
        '5. Make sure BACKEND_JWT is set in .env with a valid token'
      );
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception('Error saving quiz: $e');
    }
  }

  Future<Map<String, dynamic>> submitQuiz(List<Question> questions) async {
    // Validate API key before making request
    final key = apiKey;
    if (key.isEmpty) {
      throw Exception(
        'API key is missing or empty!\n\n'
        'Please check:\n'
        '1. Create a .env file in the project root (same folder as pubspec.yaml)\n'
        '2. Add this line: GEMINI_API_KEY=your-api-key-here\n'
        '3. Make sure there are NO spaces around the = sign\n'
        '4. Restart the app completely (hot reload won\'t work)\n'
        '5. Run: flutter pub get\n\n'
        'Get your API key from: https://aistudio.google.com/app/apikey'
      );
    }

    // Use Google Gemini API endpoint
    final model = _getEnv('GEMINI_MODEL').isEmpty ? 'gemini-2.5-flash' : _getEnv('GEMINI_MODEL');
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key"
    );

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

    final prompt = '''You are a quiz grader. Evaluate the following quiz answers and provide a score.

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
          "maxOutputTokens": 2048,
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
            throw Exception(
              'Gemini API Quota Exceeded\n\n'
              'Your API key has exceeded its usage quota.\n\n'
              'Troubleshooting steps:\n'
              '1. Check your quota and usage:\n'
              '   https://aistudio.google.com/app/apikey\n\n'
              '2. Verify your API key is valid\n\n'
              '3. Wait a few minutes and try again\n\n'
              '4. Check if you need to enable billing\n\n'
              'API Key used: ${key.substring(0, key.length > 12 ? 12 : key.length)}...\n'
              'Get a new key at: https://aistudio.google.com/app/apikey'
            );
          } else if (errorStatus == 'UNAUTHENTICATED' || errorCode == 401) {
            throw Exception(
              'Invalid API Key\n\n'
              'Your Gemini API key is invalid or has been revoked.\n\n'
              'Get a new key from:\n'
              'https://aistudio.google.com/app/apikey'
            );
          } else {
            throw Exception('Gemini API Error: $errorMessage\nStatus: $errorStatus');
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
    final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

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
}
