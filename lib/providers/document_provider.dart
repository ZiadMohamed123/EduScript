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
  Future<void> extractSimple(String image, String documentName) async {
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
      await _uploadToBackend(documentName);
    } catch (e, st) {
      errorMessage = 'Extraction failed: $e';
      document = null;
    } finally {
      isLoading = false;
      currentPage = 0;
      notifyListeners();
    }
  }

  Future<void> extractStructuredFromPdf(String documentName) async {
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
      await _uploadToBackend(documentName);
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

  /// Upload to backend AND save PDF locally
  Future<void> _uploadToBackend(String documentName) async {
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
        name: documentName,
        noOfPages: totalPages > 0 ? totalPages : null,
        token: token ?? '',
      );

      // Parse response to get document ID
      final jsonResponse = jsonDecode(response.body);
      final documentId = jsonResponse['document']['document_id'];

      if (documentId == null || documentId.toString().isEmpty) {
        throw Exception('No document_id returned from server');
      }

      await _savePdfLocally(documentId);

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

  /// Save PDF file locally so it can be accessed later
  Future<void> _savePdfLocally(String documentId) async {
    try {
      // Get app's CACHE directory instead of documents directory
      // FileProvider can access cache easier
      final directory = await getTemporaryDirectory();
      final pdfDir = Directory('${directory.path}/pdfs');

      // Create pdfs directory if it doesn't exist
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      // Copy the PDF to local storage with documentId as filename
      final localPdfPath = '${pdfDir.path}/$documentId.pdf';
      await documentFile!.copy(localPdfPath);
    } catch (e) {
      // Don't fail the whole upload if local save fails
    }
  }

  /// Get the local path for a document's PDF
  static Future<String?> getLocalPdfPath(String documentId) async {
    try {
      final directory = await getTemporaryDirectory();
      final pdfPath = '${directory.path}/pdfs/$documentId.pdf';
      final file = File(pdfPath);

      if (await file.exists()) {
        return pdfPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Default extraction method
  Future<void> extract() => extractSimple("path", "Document");

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
