import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
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

  Future<List<File>> _renderPdfToImages(File pdfFile) async {
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
        final pageImage =
            await page.render(width: page.width * 2, height: page.height * 2);
        if (pageImage != null) {
          final imageFile = File('${dir.path}/pdf_page_$i.png');
          await imageFile.writeAsBytes(pageImage.bytes);
          images.add(imageFile);
        }
        await page.close();
      } catch (_) {
        continue;
      }
    }

    await document.close();

    if (images.isEmpty) throw Exception('No pages could be rendered from PDF');

    return images;
  }

  Future<void> extractSimple(String image) async {
    if (documentFile == null) {
      errorMessage = 'No PDF loaded';
      notifyListeners();
      return;
    }

    final cacheKey = documentFile!.path;
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
        currentPage = i + 1;
        notifyListeners();

        try {
          final text =
              await OpenRouterOcrService.extractTextFromImage(images[i]);
          if (text.isNotEmpty) {
            buffer.writeln('--- Page ${i + 1} ---');
            buffer.writeln(text);
            buffer.writeln();
          }
        } catch (_) {
          buffer.writeln('--- Page ${i + 1} (OCR failed) ---');
          buffer.writeln();
        }
      }

      final resultText = buffer.toString().trim();
      if (resultText.isEmpty)
        throw Exception('OCR returned empty text for all pages');

      extractedRawText = resultText;
      await _uploadToBackend();
    } catch (e) {
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

    final cacheKey = documentFile!.path;
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
      await _uploadToBackend();
    } catch (e) {
      errorMessage = 'Structured PDF extraction failed: $e';
      document = null;
      notifyListeners();
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
    if (documentFile == null || extractedRawText.isEmpty) {
      errorMessage = 'Cannot upload: missing file or text';
      notifyListeners();
      return;
    }

    try {
      final token = await AuthService().getAuthToken();
      final response = await DocumentApiService.createDocument(
        imageFile: documentFile!,
        extractedText: extractedRawText,
        name: _titleFromPdfPath(documentFile!),
        noOfPages: totalPages > 0 ? totalPages : null,
        token: token ?? '',
      );

      final documentId = response.json['document']['document_id'];
      if (documentId == null || documentId.toString().isEmpty) {
        throw Exception('No document_id returned from server');
      }

      document = ExtractedDocument.fromRawText(
        rawText: extractedRawText,
        documentId: documentId,
      );

      _cache[documentFile!.path] = document!;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Backend upload failed: $e';
      document = null;
      notifyListeners();
      rethrow;
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

extension on Response {
  operator [](String key) {
    final jsonResponse = jsonDecode(body);
    return jsonResponse[key];
  }

  Map<String, dynamic> get json => jsonDecode(body);
}
