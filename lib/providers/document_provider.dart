import 'dart:io';
import 'package:flutter/material.dart';
import '../models/extracted_document.dart';
import '../services/data_extraction_service.dart';


class DocumentProvider with ChangeNotifier {
  final extractor = DataExtractionService();

  File? imageFile;
  String extractedRawText = "";
  ExtractedDocument? document;

  bool isLoading = false;

  Future<void> pickImage() async {
    imageFile =File('');
    notifyListeners();
  }

  Future<void> scanFromCamera() async {
    imageFile = File('');
    notifyListeners();
  }

  Future<void> extract() async {
    if (imageFile == null) return;

    isLoading = true;
    notifyListeners();

    extractedRawText = await extractor.extractText(imageFile!);

    document = ExtractedDocument.fromRawText(extractedRawText);

    isLoading = false;
    notifyListeners();
  }
}
