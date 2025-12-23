import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterOcrService {
  static String get apiKey {
    final key = dotenv.env['Api_Key_ex'];
    if (key == null || key.isEmpty) {
      throw Exception('Api_Key_ex not found in .env');
    }
    return key;
  }

  static const String baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> extractTextFromImage(
    File imageFile, {
    String model = 'google/gemini-3-flash-preview-20251217',
    int maxRetries = 3,
  }) async {
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final overallStopwatch = Stopwatch()..start();

      try {
        if (attempt == 1) {
          await _preprocessImage(imageFile);
        }

        final processedBytes = await _preprocessImage(imageFile);
        final base64Image = base64Encode(processedBytes);

        if (base64Image.length > 5 * 1024 * 1024) {
          throw Exception('Image too large. Must be under 5MB');
        }

        final response = await http
            .post(
              Uri.parse(baseUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://eduscript.app',
                'X-Title': 'EduScript AR',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {
                    'role': 'user',
                    'content': [
                      {
                        'type': 'text',
                        'text':
                            'Extract ALL text from this handwritten image. Return only the transcribed text, no commentary.'
                      },
                      {
                        'type': 'image_url',
                        'image_url': {
                          'url':
                              'data:image/jpeg;base64,$base64Image'
                        }
                      }
                    ]
                  }
                ],
                'temperature': 0.1,
                'max_tokens': 1500,
              }),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw TimeoutException('Model timeout'),
            );

        overallStopwatch.stop();

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final extractedText =
              data['choices'][0]['message']['content'];
          return extractedText.trim();
        } else if (response.statusCode == 429) {
          lastError = Exception('Rate limited');
          if (attempt < maxRetries) {
            await Future.delayed(
                Duration(seconds: attempt * 5));
            continue;
          }
        } else if (response.statusCode == 401) {
          throw Exception('Invalid API key');
        } else if (response.statusCode == 402) {
          throw Exception(
              'No credits. Add credits at https://openrouter.ai/credits');
        } else {
          lastError =
              Exception('API Error ${response.statusCode}');
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }
        }
      } on SocketException catch (e) {
        lastError = Exception('Network error: $e');
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }
      } catch (e) {
        overallStopwatch.stop();
        lastError = Exception(e);
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
      }
    }

    throw lastError ??
        Exception('OCR failed after $maxRetries attempts');
  }

  /// One-shot structured extraction
  static Future<Map<String, dynamic>> extractStructuredData(
      File imageFile) async {
    final overallStopwatch = Stopwatch()..start();

    try {
      final processedBytes = await _preprocessImage(imageFile);
      final base64Image = base64Encode(processedBytes);

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://eduscript.app',
              'X-Title': 'EduScript AR',
            },
            body: jsonEncode({
              'model': 'google/gemini-3-flash-preview-20251217',
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text': '''Extract data from this handwritten note.

Return ONLY this JSON:
{
  "title": "subject/title or null",
  "date": "YYYY-MM-DD or null",
  "studentName": "name or null",
  "questions": ["q1", "q2"],
  "rawText": "full transcribed text"
}'''
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url':
                            'data:image/jpeg;base64,$base64Image'
                      }
                    }
                  ]
                }
              ],
              'temperature': 0.1,
              'max_tokens': 2000,
            }),
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () =>
                throw TimeoutException('Timed out after 120s'),
          );

      overallStopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content =
            data['choices'][0]['message']['content']
                .toString()
                .trim();

        if (content.startsWith('```')) {
          content = content
              .replaceAll(RegExp(r'```json\s*'), '')
              .replaceAll(RegExp(r'```\s*$'), '')
              .trim();
        }

        return jsonDecode(content) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limited');
      } else {
        throw Exception(
            'API Error ${response.statusCode}');
      }
    } catch (_) {
      overallStopwatch.stop();
      rethrow;
    }
  }

  static Future<List<int>> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return bytes;

      if (image.width > 1200 || image.height > 1200) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height > image.width ? 1200 : null,
        );
      }

      image = img.grayscale(image);
      image = img.contrast(image, contrast: 120);

      return img.encodeJpg(image, quality: 80);
    } catch (_) {
      return await imageFile.readAsBytes();
    }
  }
}
