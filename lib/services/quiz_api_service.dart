// lib/services/quiz_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/question.dart';
import '../models/question_type.dart';

class QuizApiService {
  String get apiKey {
    try {
      return dotenv.env['OPENAI_API_KEY'] ?? '';
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
        '2. Add this line: OPENAI_API_KEY=sk-your-actual-key-here\n'
        '3. Make sure there are NO spaces around the = sign\n'
        '4. Restart the app completely (hot reload won\'t work)\n'
        '5. Run: flutter pub get\n\n'
        'Get your API key from: https://platform.openai.com/account/api-keys'
      );
    }

    // Use the correct OpenAI Chat Completions API endpoint
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

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

Return ONLY the JSON array, no other text.''';

    final projectId = _getEnv('OPENAI_PROJECT_ID');
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
    };
    
    // Only add OpenAI-Project header if project ID is provided
    if (projectId.isNotEmpty) {
      headers["OpenAI-Project"] = projectId;
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "model": "gpt-3.5-turbo", // Using available model from your account
        "messages": [
          {
            "role": "user",
            "content": prompt,
          }
        ],
        "temperature": 0.7,
        "response_format": {"type": "json_object"}, // Request JSON response
      }),
    );

    if (response.statusCode != 200) {
      // Parse error response for better error messages
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          final error = errorData['error'];
          final errorType = error['type'] as String?;
          final errorMessage = error['message'] as String? ?? 'Unknown error';
          final errorCode = error['code'] as String?;
          
          if (errorType == 'insufficient_quota' || errorCode == 'insufficient_quota') {
            throw Exception(
              'OpenAI API Quota Exceeded\n\n'
              'Your API key has exceeded its usage quota.\n\n'
              'Troubleshooting steps:\n'
              '1. Verify the API key belongs to an account with credits:\n'
              '   https://platform.openai.com/account/api-keys\n\n'
              '2. Check billing and usage:\n'
              '   https://platform.openai.com/account/billing\n\n'
              '3. Ensure payment method is added and verified\n\n'
              '4. Note: ChatGPT Plus subscription ≠ API credits\n'
              '   API requires separate billing setup\n\n'
              '5. If you have credits, try:\n'
              
              '   - Waiting a few minutes for billing to update\n'
              '   - Creating a new API key\n\n'
              'API Key used: ${key.substring(0, key.length > 12 ? 12 : key.length)}...\n'
              'Check this key at: https://platform.openai.com/account/api-keys'
            );
          } else if (errorType == 'invalid_api_key') {
            throw Exception(
              'Invalid API Key\n\n'
              'Your OpenAI API key is invalid or has been revoked.\n\n'
              'Get a new key from:\n'
              'https://platform.openai.com/account/api-keys'
            );
          } else if (errorType == 'rate_limit_exceeded') {
            throw Exception(
              'Rate Limit Exceeded\n\n'
              'Too many requests. Please wait a moment and try again.'
            );
          } else {
            throw Exception('OpenAI API Error: $errorMessage\nType: $errorType');
          }
        }
      } catch (e) {
        // If it's already our custom exception, rethrow it
        if (e.toString().contains('OpenAI API')) {
          rethrow;
        }
        // If parsing fails, use raw response
      }
      throw Exception("API Error (${response.statusCode}): ${response.body}");
    }

    final data = jsonDecode(response.body);

    // Chat Completions API returns content in choices[0].message.content
    final content = data['choices']?[0]?['message']?['content'] as String?;

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
}
