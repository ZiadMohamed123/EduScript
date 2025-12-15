import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';



class OpenRouterOCRService {


  /// Use this inside methods
  Future<String> extractTextFromImage(File imageFile) async {
    final apiKey = ApiConfig.nvcApiKey; // ✅ read here, AFTER dotenv is loaded
  final url = Uri.parse(
  'https://vision.googleapis.com/v1/images:annotate?key=$apiKey'
);

final response = await http.post(
  url,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    "requests": [
      {
        "image": {
          "content": base64Encode(await imageFile.readAsBytes())
        },
        "features": [
          {"type": "DOCUMENT_TEXT_DETECTION"}
        ],
        "imageContext": {"languageHints": ["ar"]} // Arabic hint
      }
    ]
  }),
);

    if (response.statusCode != 200) {
      throw Exception('OCR failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
