import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  static const String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> extractTextFromImage(
    File imageFile, {
    String model = 'google/gemini-3-flash-preview-20251217',
    int maxRetries = 3,
  }) async {
    Exception? lastError;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final overallStopwatch = Stopwatch()..start();
      
      try {
        debugPrint('');
        debugPrint('📸 Starting OCR (Attempt $attempt/$maxRetries)...');
        debugPrint('🔑 API Key: ${apiKey.substring(0, 10)}...');
        debugPrint('🤖 Model: $model');
        
        // Step 1: Preprocess image (only once)
        if (attempt == 1) {
          debugPrint('');
          debugPrint('🔄 Step 1: Preprocessing image...');
          final preprocessStopwatch = Stopwatch()..start();
          final processedBytes = await _preprocessImage(imageFile);
          preprocessStopwatch.stop();
          debugPrint('⏱️ Preprocessing completed in: ${preprocessStopwatch.elapsed.inSeconds}s');
        }
        
        final processedBytes = await _preprocessImage(imageFile);
        
        debugPrint('');
        debugPrint('📦 Step 2: Encoding to base64...');
        final encodeStopwatch = Stopwatch()..start();
        final base64Image = base64Encode(processedBytes);
        encodeStopwatch.stop();
        
        final imageSizeKB = (base64Image.length / 1024).toStringAsFixed(1);
        debugPrint('📦 Image size: ${imageSizeKB}KB (base64)');
        debugPrint('⏱️ Encoding took: ${encodeStopwatch.elapsed.inSeconds}s');
        
        if (base64Image.length > 5 * 1024 * 1024) {
          throw Exception('Image too large (${imageSizeKB}KB). Must be under 5MB');
        }

        // Step 2: Make API request
        debugPrint('');
        debugPrint('🚀 Step 3: Sending request to OpenRouter API...');
        debugPrint('🌐 Endpoint: $baseUrl');
        final apiStopwatch = Stopwatch()..start();
        
        final response = await http.post(
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
                    'text': 'Extract ALL text from this handwritten image. Return only the transcribed text, no commentary.'
                  },
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$base64Image'
                    }
                  }
                ]
              }
            ],
            'temperature': 0.1,
            'max_tokens': 1500,
          }),
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Model took longer than 60 seconds');
          },
        );

        apiStopwatch.stop();
        overallStopwatch.stop();
        
        debugPrint('⏱️ API call completed in: ${apiStopwatch.elapsed.inSeconds}s');
        debugPrint('📊 HTTP Status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          final modelUsed = data['model'] ?? 'unknown';
          debugPrint('✅ Response received from model: $modelUsed');
          
          final extractedText = data['choices'][0]['message']['content'];
          debugPrint('✅ OCR Success! Text length: ${extractedText.length} characters');
          
          debugPrint('');
          debugPrint('⏱️ TIME BREAKDOWN:');
          debugPrint('   ├─ API call: ${apiStopwatch.elapsed.inSeconds}s');
          debugPrint('   └─ TOTAL: ${overallStopwatch.elapsed.inSeconds}s');
          debugPrint('');
          
          return extractedText.trim();
          
        } else if (response.statusCode == 429) {
          final errorBody = jsonDecode(response.body);
          debugPrint('❌ Rate limit (attempt $attempt): $errorBody');
          lastError = Exception('Rate limited');
          
          if (attempt < maxRetries) {
            final waitTime = attempt * 5;
            debugPrint('⏳ Waiting ${waitTime}s before retry...');
            await Future.delayed(Duration(seconds: waitTime));
            continue;
          }
        } else if (response.statusCode == 401) {
          throw Exception('Invalid API key');
        } else if (response.statusCode == 402) {
          throw Exception('No credits. Add credits at https://openrouter.ai/credits');
        } else {
          debugPrint('❌ API Error body: ${response.body}');
          lastError = Exception('API Error ${response.statusCode}');
          
          if (attempt < maxRetries) {
            debugPrint('⏳ Retrying in 3s...');
            await Future.delayed(Duration(seconds: 3));
            continue;
          }
        }
      } on SocketException catch (e) {
        debugPrint('❌ Network error (attempt $attempt): $e');
        lastError = Exception('Network error: $e');
        
        if (attempt < maxRetries) {
          debugPrint('⏳ Retrying in 5s...');
          await Future.delayed(Duration(seconds: 5));
          continue;
        }
      } catch (e) {
        overallStopwatch.stop();
        debugPrint('');
        debugPrint('❌ OCR FAILED after ${overallStopwatch.elapsed.inSeconds}s (attempt $attempt)');
        debugPrint('❌ Error: $e');
        lastError = Exception(e);
        
        if (attempt < maxRetries) {
          debugPrint('⏳ Retrying in 3s...');
          await Future.delayed(Duration(seconds: 3));
          continue;
        }
      }
    }
    
    debugPrint('');
    debugPrint('❌ All $maxRetries attempts failed');
    throw lastError ?? Exception('OCR failed after $maxRetries attempts');
  }

  /// FASTEST: One-shot structured extraction
  static Future<Map<String, dynamic>> extractStructuredData(File imageFile) async {
    final overallStopwatch = Stopwatch()..start();
    
    try {
      debugPrint('');
      debugPrint('📸 Starting structured extraction...');
      
      // Preprocess
      debugPrint('🔄 Preprocessing...');
      final preprocessStopwatch = Stopwatch()..start();
      final processedBytes = await _preprocessImage(imageFile);
      preprocessStopwatch.stop();
      debugPrint('⏱️ Preprocessing: ${preprocessStopwatch.elapsed.inSeconds}s');
      
      final base64Image = base64Encode(processedBytes);
      debugPrint('📦 Image: ${(base64Image.length / 1024).toStringAsFixed(1)}KB');
      
      debugPrint('🚀 Calling API...');
      final apiStopwatch = Stopwatch()..start();

      final response = await http.post(
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

Return ONLY this JSON (no markdown):
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
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'temperature': 0.1,
          'max_tokens': 2000,
        }),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException('Timed out after 120s'),
      );

      apiStopwatch.stop();
      overallStopwatch.stop();
      
      debugPrint('⏱️ API call: ${apiStopwatch.elapsed.inSeconds}s');
      debugPrint('📊 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().trim();
        
        debugPrint('📝 Raw response: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');
        
        String cleanJson = content;
        if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.replaceAll(RegExp(r'```json\s*'), '');
          cleanJson = cleanJson.replaceAll(RegExp(r'```\s*$'), '');
          cleanJson = cleanJson.trim();
        }
        
        final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
        debugPrint('✅ Structured extraction success!');
        debugPrint('⏱️ Total time: ${overallStopwatch.elapsed.inSeconds}s');
        debugPrint('');
        return parsed;
        
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limited');
      } else {
        debugPrint('❌ Error body: ${response.body}');
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      overallStopwatch.stop();
      debugPrint('❌ Structured extraction failed after ${overallStopwatch.elapsed.inSeconds}s: $e');
      debugPrint('');
      rethrow;
    }
  }

  // preprocess the image first
  static Future<List<int>> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      debugPrint('   📂 Original file size: ${(bytes.length / 1024).toStringAsFixed(1)}KB');
      
      final decodeStopwatch = Stopwatch()..start();
      img.Image? image = img.decodeImage(bytes);
      decodeStopwatch.stop();
      debugPrint('   ⏱️ Image decode: ${decodeStopwatch.elapsedMilliseconds}ms');
      
      if (image == null) {
        debugPrint('   ⚠️ Could not decode image, using original');
        return bytes;
      }

      debugPrint('   📐 Original dimensions: ${image.width}x${image.height}');

      if (image.width > 1200 || image.height > 1200) {
        final resizeStopwatch = Stopwatch()..start();
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height > image.width ? 1200 : null,
        );
        resizeStopwatch.stop();
        debugPrint('   🔄 Resized to: ${image.width}x${image.height} (${resizeStopwatch.elapsedMilliseconds}ms)');
      } else {
        debugPrint('   ✅ No resize needed');
      }

      final grayscaleStopwatch = Stopwatch()..start();
      image = img.grayscale(image);
      grayscaleStopwatch.stop();
      debugPrint('   🎨 Grayscale applied (${grayscaleStopwatch.elapsedMilliseconds}ms)');

      final contrastStopwatch = Stopwatch()..start();
      image = img.contrast(image, contrast: 120);
      contrastStopwatch.stop();
      debugPrint('   ✨ Contrast enhanced (${contrastStopwatch.elapsedMilliseconds}ms)');

      final encodeStopwatch = Stopwatch()..start();
      final compressed = img.encodeJpg(image, quality: 80);
      encodeStopwatch.stop();
      debugPrint('   📦 Compressed to: ${(compressed.length / 1024).toStringAsFixed(1)}KB (${encodeStopwatch.elapsedMilliseconds}ms)');
      debugPrint('   💾 Size reduction: ${((1 - compressed.length / bytes.length) * 100).toStringAsFixed(1)}%');
      
      return compressed;
    } catch (e) {
      debugPrint('   ⚠️ Preprocessing failed: $e');
      debugPrint('   ↩️ Using original image');
      return await imageFile.readAsBytes();
    }
  }
}