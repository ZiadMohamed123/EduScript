import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/extracted_document.dart';
import '../services/data_extraction_service.dart';
import '../services/OpenRouterOCRService.dart';

class DocumentProvider with ChangeNotifier {
  final ocrService = OpenRouterOCRService();
  final extractor = DataExtractionService();

  File? imageFile;
  String extractedRawText = "";
  ExtractedDocument? document;
  bool isLoading = false;
Future<void> loadDemoImage() async {
  try {
    final byteData = await rootBundle.load('assets/image.jpg');
    final bytes = byteData.buffer.asUint8List();

    // ✅ Get writable directory
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/demo_image.jpg');

    await file.writeAsBytes(bytes, flush: true);

    imageFile = file;
    debugPrint('Image loaded: ${file.path}');
    notifyListeners();
  } catch (e, st) {
    debugPrint('Error loading image: $e');
    debugPrint('$st');
  }
}
  Future<void> extract() async {
    if (imageFile == null) return;

    isLoading = true;
    notifyListeners();

    try {
      // 🔹 FREE OCR using Nemotron VL
      extractedRawText =
          await ocrService.extractTextFromImage(imageFile!);

      debugPrint('OCR TEXT:\n$extractedRawText');

      // 🔹 Structure it (your existing logic)
      final jsonString =
          await extractor.extractWithAI( extractedRawText);

      document = ExtractedDocument.fromJson(jsonString);
    } catch (e) {
      debugPrint('Extraction error: $e');
      document = null;
    }

    isLoading = false;
    notifyListeners();
  }
}

