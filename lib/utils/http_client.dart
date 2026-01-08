import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';

/// HTTP Client helper that automatically includes JWT token in requests
class HttpClient {
  /// Get headers with JWT token if available
  static Future<Map<String, String>> getHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    if (includeAuth) {
      final token = await AuthService().getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// GET request with automatic JWT token
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}$endpoint');
      final requestHeaders = await getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      return await http.get(uri, headers: requestHeaders).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
            'Please check:\n'
            '1. Is your backend server running? (cd backend && npm start)\n'
            '2. Is the server running on port 5000?\n'
            '3. Check your BACKEND_URL in .env file\n'
            '4. For Android emulator, use: http://10.0.2.2:5000\n'
            '5. For physical device, use your computer\'s IP address'
          );
        },
      );
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception(
        'Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
        'Error: ${e.toString()}\n\n'
        'Please check:\n'
        '1. Is your backend server running? (cd backend && npm start)\n'
        '2. Check your BACKEND_URL in .env file\n'
        '3. For Android emulator, use: http://10.0.2.2:5000\n'
        '4. For physical device, use your computer\'s IP address'
      );
    }
  }

  /// POST request with automatic JWT token
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}$endpoint');
      final requestHeaders = await getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      return await http.post(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
            'Please check:\n'
            '1. Is your backend server running? (cd backend && npm start)\n'
            '2. Is the server running on port 5000?\n'
            '3. Check your BACKEND_URL in .env file\n'
            '4. For Android emulator, use: http://10.0.2.2:5000\n'
            '5. For physical device, use your computer\'s IP address'
          );
        },
      );
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception(
        'Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
        'Error: ${e.toString()}\n\n'
        'Please check:\n'
        '1. Is your backend server running? (cd backend && npm start)\n'
        '2. Check your BACKEND_URL in .env file\n'
        '3. For Android emulator, use: http://10.0.2.2:5000\n'
        '4. For physical device, use your computer\'s IP address'
      );
    }
  }

  /// PUT request with automatic JWT token
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}$endpoint');
      final requestHeaders = await getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      return await http.put(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
            'Please check:\n'
            '1. Is your backend server running? (cd backend && npm start)\n'
            '2. Is the server running on port 5000?\n'
            '3. Check your BACKEND_URL in .env file\n'
            '4. For Android emulator, use: http://10.0.2.2:5000\n'
            '5. For physical device, use your computer\'s IP address'
          );
        },
      );
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception(
        'Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
        'Error: ${e.toString()}\n\n'
        'Please check:\n'
        '1. Is your backend server running? (cd backend && npm start)\n'
        '2. Check your BACKEND_URL in .env file\n'
        '3. For Android emulator, use: http://10.0.2.2:5000\n'
        '4. For physical device, use your computer\'s IP address'
      );
    }
  }

  /// DELETE request with automatic JWT token
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}$endpoint');
      final requestHeaders = await getHeaders(
        additionalHeaders: headers,
        includeAuth: includeAuth,
      );
      return await http.delete(uri, headers: requestHeaders).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
            'Please check:\n'
            '1. Is your backend server running? (cd backend && npm start)\n'
            '2. Is the server running on port 5000?\n'
            '3. Check your BACKEND_URL in .env file\n'
            '4. For Android emulator, use: http://10.0.2.2:5000\n'
            '5. For physical device, use your computer\'s IP address'
          );
        },
      );
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception(
        'Could not connect to server at ${ApiConfig.backendBaseUrl}\n\n'
        'Error: ${e.toString()}\n\n'
        'Please check:\n'
        '1. Is your backend server running? (cd backend && npm start)\n'
        '2. Check your BACKEND_URL in .env file\n'
        '3. For Android emulator, use: http://10.0.2.2:5000\n'
        '4. For physical device, use your computer\'s IP address'
      );
    }
  }

  /// POST request with multipart/form-data (for file uploads)
  static Future<http.Response> postMultipart(
    String endpoint,
    http.MultipartRequest request, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.backendBaseUrl}$endpoint');

    // Create new request with correct URL
    final newRequest = http.MultipartRequest(request.method, uri)
      ..fields.addAll(request.fields)
      ..files.addAll(request.files);

    if (includeAuth) {
      final token = await AuthService().getAuthToken();
      if (token != null && token.isNotEmpty) {
        newRequest.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Copy other headers
    newRequest.headers.addAll(request.headers);

    final streamedResponse = await newRequest.send();
    return await http.Response.fromStream(streamedResponse);
  }

  /// PUT request with multipart/form-data (for file uploads)
  static Future<http.Response> putMultipart(
    String endpoint,
    http.MultipartRequest request, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.backendBaseUrl}$endpoint');

    // Create new request with correct URL and PUT method
    final newRequest = http.MultipartRequest('PUT', uri)
      ..fields.addAll(request.fields);
    
    // Copy files while preserving content type
    for (final file in request.files) {
      newRequest.files.add(file);
    }

    if (includeAuth) {
      final token = await AuthService().getAuthToken();
      if (token != null && token.isNotEmpty) {
        newRequest.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Don't override Content-Type header - let multipart request set it
    // Copy other headers except Content-Type
    request.headers.forEach((key, value) {
      if (key.toLowerCase() != 'content-type') {
        newRequest.headers[key] = value;
      }
    });

    final streamedResponse = await newRequest.send();
    return await http.Response.fromStream(streamedResponse);
  }
}