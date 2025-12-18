// lib/services/quiz_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
