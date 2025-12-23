import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utils/http_client.dart';
import '../services/auth_service.dart';

/// User Service
/// Handles user profile and settings operations using JWT authentication
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  /// Get user profile and settings
  /// Requires JWT token (automatically included)
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await HttpClient.get('/user/');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile picture
  /// Requires JWT token (automatically included)
  /// Returns the image bytes or null if not found
  Future<Uint8List?> getProfilePicture() async {
    try {
      final response = await HttpClient.get('/user/profile-picture');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        // Profile picture not found, return null
        return null;
      } else {
        throw Exception('Failed to get profile picture: ${response.statusCode}');
      }
    } catch (e) {
      // Return null if profile picture doesn't exist
      return null;
    }
  }

  /// Update user profile with multipart/form-data
  /// Supports name, email, and profile picture upload
  /// Requires JWT token (automatically included)
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    File? profilePicture,
    String? mimeType,
  }) async {
    try {
      // Create multipart request (URI will be set by HttpClient.putMultipart)
      final request = http.MultipartRequest('PUT', Uri.parse('http://placeholder'));

      // Add fields if provided
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }

      // Add profile picture file if provided
      if (profilePicture != null && await profilePicture.exists()) {
        final fileLength = await profilePicture.length();
        final fileName = profilePicture.path.split('/').last;
        
        // Read first few bytes to detect image type
        final fileBytes = await profilePicture.readAsBytes();
        String contentType;
        
        // Detect image type from file signature (magic bytes)
        if (fileBytes.length >= 2) {
          // JPEG: FF D8 FF
          if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8) {
            contentType = 'image/jpeg';
          }
          // PNG: 89 50 4E 47
          else if (fileBytes.length >= 4 && 
                   fileBytes[0] == 0x89 && 
                   fileBytes[1] == 0x50 && 
                   fileBytes[2] == 0x4E && 
                   fileBytes[3] == 0x47) {
            contentType = 'image/png';
          }
          // WebP: Check for "RIFF" and "WEBP"
          else if (fileBytes.length >= 12 &&
                   fileBytes[0] == 0x52 && fileBytes[1] == 0x49 && 
                   fileBytes[2] == 0x46 && fileBytes[3] == 0x46 &&
                   fileBytes[8] == 0x57 && fileBytes[9] == 0x45 && 
                   fileBytes[10] == 0x42 && fileBytes[11] == 0x50) {
            contentType = 'image/webp';
          }
          // Fallback to provided mimeType or extension
          else {
            if (mimeType != null && mimeType.isNotEmpty) {
              contentType = mimeType;
              if (contentType == 'image/jpg') {
                contentType = 'image/jpeg';
              }
            } else {
              // Extension-based fallback
              final parts = fileName.split('.');
              final fileExtension = parts.length > 1 ? parts.last.toLowerCase() : '';
              switch (fileExtension) {
                case 'jpg':
                case 'jpeg':
                  contentType = 'image/jpeg';
                  break;
                case 'png':
                  contentType = 'image/png';
                  break;
                case 'webp':
                  contentType = 'image/webp';
                  break;
                default:
                  contentType = 'image/jpeg'; // Default
              }
            }
          }
        } else {
          // File too small, use fallback
          contentType = mimeType ?? 'image/jpeg';
          if (contentType == 'image/jpg') {
            contentType = 'image/jpeg';
          }
        }
        
        // Validate that the content type is allowed by backend
        final allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
        if (!allowedTypes.contains(contentType)) {
          throw Exception('Invalid image type: $contentType. Allowed: JPEG, PNG, WebP');
        }
        
        // Debug: Print what we're sending
        print('Uploading image: $fileName');
        print('Detected Content-Type: $contentType');
        print('MIME Type from XFile: $mimeType');
        print('File path: ${profilePicture.path}');
        print('File size: $fileLength bytes');
        
        // Ensure filename has proper extension
        String finalFileName = fileName;
        if (!fileName.toLowerCase().endsWith('.jpg') && 
            !fileName.toLowerCase().endsWith('.jpeg') && 
            !fileName.toLowerCase().endsWith('.png') && 
            !fileName.toLowerCase().endsWith('.webp')) {
          if (contentType == 'image/jpeg') {
            finalFileName = '$fileName.jpg';
          } else if (contentType == 'image/png') {
            finalFileName = '$fileName.png';
          } else if (contentType == 'image/webp') {
            finalFileName = '$fileName.webp';
          }
        }
        
        // Create file stream and multipart file
        final fileStream = http.ByteStream.fromBytes(fileBytes);
        final multipartFile = http.MultipartFile(
          'profilePicture',
          fileStream,
          fileLength,
          filename: finalFileName,
          contentType: http.MediaType.parse(contentType),
        );
        request.files.add(multipartFile);
      }

      // Send multipart request
      final response = await HttpClient.putMultipart(
        '/user/update',
        request,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        final errorBody = response.body.isNotEmpty 
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        final errorMessage = errorBody?['message'] as String?;
        
        // Provide more detailed error message for file type errors
        String detailedError = errorMessage ?? 'Failed to update profile: ${response.statusCode}';
        if (errorMessage != null && 
            (errorMessage.toLowerCase().contains('image type') || 
             errorMessage.toLowerCase().contains('file type'))) {
          if (profilePicture != null) {
            final fileName = profilePicture.path.split('/').last;
            final parts = fileName.split('.');
            final fileExtension = parts.length > 1 ? parts.last.toLowerCase() : 'unknown';
            detailedError = 'Invalid image type: .$fileExtension\n\n'
                'Allowed formats: JPEG (.jpg, .jpeg), PNG (.png), WebP (.webp)\n\n'
                'Please select a different image.';
          }
        }
        
        throw Exception(detailedError);
      }
    } catch (e) {
      rethrow;
    }
  }


  /// Toggle dark mode setting
  /// Requires JWT token (automatically included)
  Future<Map<String, dynamic>> toggleDarkMode() async {
    try {
      final response = await HttpClient.put(
        '/user/settings/darkmode',
        body: {}, // Send empty JSON object
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        final errorBody = response.body.isNotEmpty 
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        final errorMessage = errorBody?['message'] as String?;
        throw Exception(errorMessage ?? 'Failed to toggle dark mode: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update language setting
  /// Requires JWT token (automatically included)
  Future<Map<String, dynamic>> updateLanguage(String language) async {
    try {
      final response = await HttpClient.put(
        '/user/settings/language',
        body: {'language': language},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to update language: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user account
  /// Requires JWT token (automatically included)
  Future<void> deleteAccount() async {
    try {
      final response = await HttpClient.delete('/user/delete');

      if (response.statusCode == 200) {
        // Logout after account deletion
        await AuthService().logout();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}





