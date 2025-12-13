import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleVisionApiService {
  static const String apiKey = "YOUR_API_KEY";

  static Future<Map<String, dynamic>> detectDocument(Uint8List bytes) async {
    final base64Image = base64Encode(bytes);

    final body = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [{"type": "DOCUMENT_TEXT_DETECTION"}],
          "imageContext": {"languageHints": ["ar"]}
        }
      ]
    };

    final response = await http.post(
      Uri.parse(
        "https://vision.googleapis.com/v1/images:annotate?key=$apiKey",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }
}
