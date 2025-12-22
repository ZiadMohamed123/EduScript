import 'dart:io';
import 'package:http/http.dart' as http;

class DocumentApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

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
    'document', // ✅ MUST match API docs
    imageFile.path,
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
