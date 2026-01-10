import 'dart:io';

import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DocumentApiService {
  static const String baseUrl = 'http://192.168.1.5:5000';
  static final Dio _dio = Dio();

  static Future<http.Response> createDocument({
    required File imageFile,
    required String extractedText,
    required String token,
    String? name,
    int? noOfPages,
    String? summary,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: DioMediaType.parse('application/pdf'),
        ),
        'name': name ?? imageFile.path.split('/').last,
        'extractedText': extractedText,
        'noOfPages': noOfPages?.toString() ?? '',
        if (summary != null) 'summary': summary,
      });

      final response = await _dio.post(
        '$baseUrl/document/add',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // Convert dio.Response directly without jsonEncode
      return http.Response(
        response.data is String ? response.data : jsonEncode(response.data),
        response.statusCode ?? 500,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e) {
      rethrow;
    }
  }
}
