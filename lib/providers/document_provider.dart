import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import '../models/extracted_document.dart';
import '../services/OpenRouterOCRService.dart';
import '../services/document_api_service.dart';
import '../services/auth_service.dart';

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

  /// Convert PDF → images using pdfx (stable and maintained)
  Future<List<File>> _renderPdfToImages(File pdfFile) async {
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;
      totalPages = pageCount;

      final dir = await getTemporaryDirectory();
      final List<File> images = [];

      for (int i = 1; i <= pageCount; i++) {
        currentPage = i;
        notifyListeners();

        try {
          final page = await document.getPage(i);

          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
          );

          if (pageImage == null) {
            continue;
          }

          final imageFile = File('${dir.path}/pdf_page_$i.png');
          await imageFile.writeAsBytes(pageImage.bytes);
          images.add(imageFile);

          await page.close();
        } catch (e) {
          continue;
        }
      }

      await document.close();

      if (images.isEmpty) {
        throw Exception('No pages could be rendered from PDF');
      }

      return images;
    } catch (e, st) {
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

    final cacheKey = '${documentFile!.path}_simple';
    if (_cache.containsKey(cacheKey)) {
      document = _cache[cacheKey];
      extractedRawText = document?.rawText ?? '';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    currentPage = 0;
    totalPages = 0;
    notifyListeners();

    try {
      final images = await _renderPdfToImages(documentFile!);

      StringBuffer buffer = StringBuffer();
      final totalPages = images.length;

      for (int i = 0; i < totalPages; i++) {
        try {
          currentPage = i + 1;
          notifyListeners();

          final text =
              await OpenRouterOcrService.extractTextFromImage(images[i]);

          if (text.isNotEmpty) {
            buffer.writeln('--- Page ${i + 1} ---');
            buffer.writeln(text);
            buffer.writeln();
          }
        } catch (e) {
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

      await _uploadToBackend();
    } catch (e, st) {
      errorMessage = 'Extraction failed: $e';
      document = null;
    } finally {
      isLoading = false;
      currentPage = 0;
      notifyListeners();
    }
  }

  Future<void> extractStructuredFromPdf() async {
    if (documentFile == null) {
      errorMessage = 'No PDF loaded';
      notifyListeners();
      return;
    }

    final cacheKey = '${documentFile!.path}_structured_pdf';
    if (_cache.containsKey(cacheKey)) {
      document = _cache[cacheKey];
      extractedRawText = document?.rawText ?? '';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    currentPage = 0;
    totalPages = 0;
    notifyListeners();

    try {
      final images = await _renderPdfToImages(documentFile!);

      StringBuffer fullText = StringBuffer();

      for (int i = 0; i < images.length; i++) {
        currentPage = i + 1;
        notifyListeners();

        try {
          final structured =
              await OpenRouterOcrService.extractStructuredData(images[i]);

          final pageText = structured['rawText'] ?? '';

          if (pageText.isNotEmpty) {
            fullText.writeln('--- Page ${i + 1} ---');
            fullText.writeln(pageText);
            fullText.writeln();
          }
        } catch (_) {
          fullText.writeln('--- Page ${i + 1} (failed) ---');
          fullText.writeln();
        }
      }

      extractedRawText = fullText.toString().trim();

      document = ExtractedDocument.fromRawText(extractedRawText);
      _cache[cacheKey] = document!;

      await _uploadToBackend();
    } catch (e) {
      errorMessage = 'Structured PDF extraction failed: $e';
      document = null;
    } finally {
      isLoading = false;
      currentPage = 0;
      notifyListeners();
    }
  }

  String _titleFromPdfPath(File pdfFile) {
    final name = pdfFile.path.split('/').last.replaceAll('.pdf', '');
    return name.replaceAll('_', ' ');
  }

  /// Upload to backend
  Future<void> _uploadToBackend() async {
    try {
      if (documentFile == null || extractedRawText.isEmpty) return;

      final AuthService _authService = AuthService();
      final token = await _authService.getAuthToken();
      final response = await DocumentApiService.createDocument(
        imageFile: documentFile!,
        extractedText: extractedRawText,
        name: _titleFromPdfPath(documentFile!),
        noOfPages: totalPages > 0 ? totalPages : null,
        token: token ?? '',
      );
    } catch (e) {
      // Silent fail
    }
  }

  /// Default extraction method
  Future<void> extract() => extractSimple("path");

  void clearCache() {
    _cache.clear();
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
