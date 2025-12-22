import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/extracted_document.dart';
import '../services/OpenRouterOCRService.dart';
import '../services/document_api_service.dart';
class DocumentProvider with ChangeNotifier {
  final Map<String, ExtractedDocument> _cache = {};
  
  File? imageFile;
  String extractedRawText = "";
  ExtractedDocument? document;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadDemoImage() async {
    try {
      final byteData = await rootBundle.load('assets/الشخصيات _2.jpg');
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/demo_image.jpg');
      await file.writeAsBytes(bytes, flush: true);

      imageFile = file;
      errorMessage = null;
      debugPrint('✅ Image loaded: ${file.path}');
      
      // Check file size
      final sizeKB = (bytes.length / 1024).toStringAsFixed(1);
      debugPrint('📦 File size: ${sizeKB}KB');
      
      notifyListeners();
    } catch (e, st) {
      debugPrint('❌ Error loading image: $e\n$st');
      errorMessage = 'Failed to load image: $e';
      notifyListeners();
    }
  }

Future<void> extractSimple() async {
  if (imageFile == null) return;

  isLoading = true;
  errorMessage = null;
  notifyListeners();

  try {
    // 1️⃣ OCR
    extractedRawText =
        await OpenRouterOcrService.extractTextFromImage(imageFile!);

    // Basic validation
    if (extractedRawText.trim().length < 20) {
      throw Exception('Extraction too short');
    }

    document = ExtractedDocument.fromRawText(extractedRawText);



    debugPrint('✅ Document saved to backend');

  } catch (e) {
    errorMessage = 'Extraction failed. Document not saved.';
    document = null;
  }

  isLoading = false;
  notifyListeners();
}

  /// ADVANCED: Structured extraction (slower but better)
  Future<void> extractStructured() async {
    if (imageFile == null) {
      errorMessage = 'No image loaded';
      notifyListeners();
      return;
    }

    // Check cache
    final cacheKey = imageFile!.path;
    if (_cache.containsKey(cacheKey)) {
      document = _cache[cacheKey]!;
      extractedRawText = 'Cached result';
      debugPrint('⚡ Used cache');
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🚀 Starting structured extraction...');
      final stopwatch = Stopwatch()..start();
      
      final structured = await OpenRouterOcrService.extractStructuredData(imageFile!);
      
      // Parse response
      List<String> questionsList = [];
      if (structured['questions'] is List) {
        questionsList = List<String>.from(
          (structured['questions'] as List).map((e) => e.toString())
        );
      }
      
      document = ExtractedDocument(
        title: structured['title']?.toString(),
        date: structured['date']?.toString(),
        studentName: structured['studentName']?.toString(),
        questions: questionsList,
      );
      
      extractedRawText = structured['rawText']?.toString() ?? '';
      _cache[cacheKey] = document!;
      
      stopwatch.stop();
      debugPrint('⏱️ Total: ${stopwatch.elapsed.inSeconds}s');
      debugPrint('✅ Found ${questionsList.length} questions');
          // 2️⃣ ONLY AFTER SUCCESS → upload to backend
final response = await DocumentApiService.createDocument(
  imageFile: imageFile!,
  extractedText: extractedRawText,
  name: document?.title ?? 'Scanned Document',
  noOfPages: document?.questions.length,
  token: "af66909b-54a4-425f-a5de-cfc585a5eb1e", // REAL JWT
);

if (response.statusCode != 201) {
  throw Exception(response.body);
}
    } catch (e, st) {
      debugPrint('❌ Structured extraction error: $e');
      debugPrint('Stack: $st');
      
      if (e.toString().contains('Invalid API key')) {
        errorMessage = 'Invalid API key. Get one at https://openrouter.ai/keys';
      } else if (e.toString().contains('Rate limited')) {
        errorMessage = 'Too many requests. Wait and try again.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Image might be too complex.';
      } else {
        errorMessage = 'Failed: ${e.toString().substring(0, 100)}';
      }
      
      document = null;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> extract() async {
    await extractSimple(); 
  }

  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Cache cleared');
  }
}