import 'dart:io';
import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class DataExtractionService {
  final textRecognizer = TextRecognizer();

  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    return recognizedText.text;
  }

  Future<String> extractWithAI(String scannedText) async {
    try {
      final apiKey = dotenv.env['NVC_API_KEY'];
      final model = dotenv.env['OPENROUTER_MODEL'] ?? 'openai/gpt-4o-mini';

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured');
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          "max_tokens": 2000,
          'messages': [
            {
              'role': 'user',
              'content':
                  '''Extract structured data from this scanned document text:

$scannedText

Extract and return ONLY valid JSON (no markdown, no code blocks) with this structure:
{
  "title": "document title or subject",
  "date": "date in YYYY-MM-DD format or null",
  "studentName": "student name if present or null",
  "questions": ["question 1", "question 2", ...]
}

Be strict with JSON format. Return ONLY the JSON object.''',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content']
            .toString()
            .trim();

        // Remove markdown code blocks if present
        String cleanJson = content;
        if (content.contains('```json')) {
          cleanJson = content
              .replaceAll(RegExp(r'```json\n?'), '')
              .replaceAll(RegExp(r'\n?```'), '');
        } else if (content.contains('```')) {
          cleanJson = content
              .replaceAll(RegExp(r'```\n?'), '')
              .replaceAll(RegExp(r'\n?```'), '');
        }

        return cleanJson.trim();
      } else {
        final error = jsonDecode(response.body);
        throw Exception('API Error: ${error['error']['message']}');
      }
    } catch (e) {
      debugPrint('AI Extraction Error: $e');
      rethrow;
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}
