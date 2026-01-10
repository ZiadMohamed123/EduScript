import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/api_config.dart';
class DocumentApiService {
  static String get baseUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['BACKEND_URL'] ?? '';
    } else {
      return ApiConfig.backendBaseUrl;
    }
  }

  static Future<http.Response> createDocument({
    required File imageFile,
    required String extractedText,
    required String token,
    String? name,
    int? noOfPages,
    String? summary,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/document/add'),
    );

    // Authorization
    request.headers['Authorization'] = 'Bearer $token';

    // File (MUST match multer field name)
    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        imageFile.path,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    // Fields
    request.fields['name'] = name ?? imageFile.path.split('/').last;
    request.fields['extractedText'] = extractedText;

    if (noOfPages != null) {
      request.fields['noOfPages'] = noOfPages.toString();
    }

    if (summary != null) {
      request.fields['summary'] = summary;
    }

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return response;
  }
}
