import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart'; // ✅ Changed from pdf_render
import '../models/extracted_document.dart';
import '../services/OpenRouterOCRService.dart';
import '../services/document_api_service.dart';

class DocumentProvider with ChangeNotifier {
  final Map<String, ExtractedDocument> _cache = {};

  File? documentFile;
  File? imageFile;
  String extractedRawText = "";
  ExtractedDocument? document;
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;

  /// Load demo PDF from assets
  Future<void> loadDemoPdf() async {
    try {
      final byteData = await rootBundle.load('assets/Untitled design.pdf');
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/demo_document.pdf');
      await file.writeAsBytes(bytes, flush: true);

      documentFile = file;
      errorMessage = null;

      debugPrint('✅ PDF loaded: ${file.path}');
      debugPrint('📦 Size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');

      notifyListeners();
    } catch (e, st) {
      errorMessage = 'Failed to load PDF: $e';
      debugPrint('❌ PDF load error: $e\n$st');
      notifyListeners();
    }
  }

  /// Convert PDF → images using pdfx (stable and maintained)
  Future<List<File>> _renderPdfToImages(File pdfFile) async {
    try {
      debugPrint('📄 Opening PDF: ${pdfFile.path}');
      
      // Load PDF document
      final document = await PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;
      totalPages = pageCount;
      
      debugPrint('📚 PDF has $pageCount pages');

      final dir = await getTemporaryDirectory();
      final List<File> images = [];

      // Render each page
      for (int i = 1; i <= pageCount; i++) {
        currentPage = i;
        notifyListeners(); // Update UI with progress

        try {
          debugPrint('🖼️ Rendering page $i/$pageCount...');
          
          final page = await document.getPage(i);
          
          // Render at 2x resolution for better OCR
          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
          );

          if (pageImage == null) {
            debugPrint('⚠️ Page $i returned null image');
            continue;
          }

          // PdfPageImage already contains the image data
          final imageFile = File('${dir.path}/pdf_page_$i.png');
          await imageFile.writeAsBytes(pageImage.bytes);
          images.add(imageFile);
          
          final fileSize = await imageFile.length();
          debugPrint('✅ Page $i saved (${(fileSize / 1024).toStringAsFixed(1)}KB)');
          
          await page.close();
          
        } catch (e) {
          debugPrint('❌ Failed to render page $i: $e');
          continue; // Skip this page, try next
        }
      }

      await document.close();

      if (images.isEmpty) {
        throw Exception('No pages could be rendered from PDF');
      }

      debugPrint('✅ Successfully rendered ${images.length}/$pageCount pages');
      return images;
    } catch (e, st) {
      debugPrint('❌ PDF rendering error: $e\n$st');
      rethrow;
    }
  }

  /// Simple OCR for PDF (page by page)
  Future<void> extractSimple(String image) async {
    if (documentFile == null) {
      errorMessage = 'No PDF loaded';
      notifyListeners();
      return;
    }

    // Check cache
    final cacheKey = '${documentFile!.path}_simple';
    if (_cache.containsKey(cacheKey)) {
      document = _cache[cacheKey];
      extractedRawText = document?.rawText ?? '';
      debugPrint('⚡ Used cached result');
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    currentPage = 0;
    totalPages = 0;
    notifyListeners();

    try {
      // Step 1: Render PDF to images
      final images = await _renderPdfToImages(documentFile!);
      
      // Step 2: OCR each page
      StringBuffer buffer = StringBuffer();
      final totalPages = images.length;

      for (int i = 0; i < totalPages; i++) {
        try {
          currentPage = i + 1;
          notifyListeners();
          
          debugPrint('🔍 OCR page ${i + 1}/$totalPages...');
          
          final text = await OpenRouterOcrService.extractTextFromImage(images[i]);
          
          if (text.isNotEmpty) {
            buffer.writeln('--- Page ${i + 1} ---');
            buffer.writeln(text);
            buffer.writeln();
          }
          
          debugPrint('✅ Page ${i + 1} done (${text.length} chars)');
        } catch (e) {
          debugPrint('❌ OCR failed for page ${i + 1}: $e');
          buffer.writeln('--- Page ${i + 1} (OCR failed) ---');
          buffer.writeln();
        }
      }

      final resultText = buffer.toString().trim();
      if (resultText.isEmpty) {
        throw Exception('OCR returned empty text for all pages');
      }

      extractedRawText = resultText;
      document = ExtractedDocument.fromRawText(extractedRawText);
      _cache[cacheKey] = document!;

      debugPrint('✅ PDF OCR completed');
      debugPrint('📝 Total text length: ${extractedRawText.length}');

      await _uploadToBackend();

    } catch (e, st) {
      errorMessage = 'Extraction failed: $e';
      debugPrint('❌ Extraction error: $e\n$st');
      document = null;
    } finally {
      isLoading = false;
      currentPage = 0;
      notifyListeners();
    }
  }

  /// Structured OCR (all pages at once - faster)
  Future<void> extractStructured(File image) async {
    if (documentFile == null) {
      errorMessage = 'No PDF loaded';
      notifyListeners();
      return;
    }
    
    final cacheKey = '${documentFile!.path}_structured';
    if (_cache.containsKey(cacheKey)) {
      document = _cache[cacheKey];
      extractedRawText = document?.rawText ?? '';
      debugPrint('⚡ Used cached structured result');
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
    
      
      debugPrint('🔍 Structured extraction (page 1)...');
      
      final structured = await OpenRouterOcrService.extractStructuredData(image);
      
      extractedRawText = structured['rawText'] ?? '';
      
      document = ExtractedDocument(
        title: structured['title'],
        date: structured['date'],
        studentName: structured['studentName'],
        questions: List<String>.from(structured['questions'] ?? []),
        rawText: extractedRawText,
      );
      
      _cache[cacheKey] = document!;

      debugPrint('✅ Structured extraction complete');
      await _uploadToBackend();
    } catch (e, st) {
      errorMessage = 'Structured extraction failed: $e';
      debugPrint('❌ Error: $e\n$st');
      document = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

/// Upload to backend
Future<void> _uploadToBackend() async {
  try {
    if (documentFile == null || extractedRawText.isEmpty) return;

    debugPrint('📤 Uploading to backend...');
    debugPrint('📄 File: ${documentFile!.path}');
    debugPrint('📝 File extension: ${documentFile!.path.split('.').last}');
    
    final response = await DocumentApiService.createDocument(
      imageFile: documentFile!, 
      extractedText: extractedRawText,
      name: document?.title ?? 'Scanned Document',
      noOfPages: totalPages > 0 ? totalPages : null,
      token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNzg5NjBlYTktMmUyNi00YjhiLWI2MTUtMjE1MmQ1ZjFhYmJhIiwiZW1haWwiOiJ1c2VyQGdtYWlsLmNvbSIsImlhdCI6MTc2NjQzNDkxNCwiZXhwIjoxNzY3MDM5NzE0fQ.mFzF6IVn5Vx0y8NVZW4N8k3qwDM8Pz1zQ2EMDDsLO-o",
    );

    if (response.statusCode == 201) {
      debugPrint('✅ Upload successful: ${response.body}');
    } else {
      debugPrint('⚠️ Upload failed: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
    }
  } catch (e) {
    debugPrint('❌ Upload error: $e');
  }
}

  /// Default extraction method
  Future<void> extract() => extractSimple("path");

  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Cache cleared');
  }

  void reset() {
    documentFile = null;
    extractedRawText = "";
    document = null;
    isLoading = false;
    errorMessage = null;
    currentPage = 0;
    totalPages = 0;
    notifyListeners();
  }
}