import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;
import 'dart:io' show Platform;

class ApiConfig {
  /// Base URL for the backend API
  /// For web development, make sure your backend server is running and accessible
  /// If using CORS, ensure your backend allows requests from your Flutter web origin
  static String get backendBaseUrl {
    // First, try to get URL from environment variables
    if (dotenv.isInitialized) {
      final url = dotenv.env['BACKEND_URL']?.trim() ??
          dotenv.env['BACKEND_BASE_URL']?.trim();

      if (url != null && url.isNotEmpty) {
        // Ensure URL has http:// or https://
        if (!url.startsWith('http')) {
          return 'http://$url';
        }
        return url;
      }
    }

    // Auto-detect based on platform if no .env URL is set
    if (kIsWeb) {
      // Chrome/Web browser
      developer.log('Using default backend URL for Web: http://localhost:5000');
      return 'http://localhost:5000';
    } else {
      // Mobile/Desktop platforms
      try {
        if (Platform.isAndroid) {
          // Android Emulator (10.0.2.2 maps to host's localhost)
          // For physical Android devices, you need to set BACKEND_URL to your computer's IP
          developer.log(
              'Using default backend URL for Android: http://10.0.2.2:5000');
          return 'http://10.0.2.2:5000';
        } else if (Platform.isIOS) {
          // iOS Simulator
          developer
              .log('Using default backend URL for iOS: http://localhost:5000');
          return 'http://localhost:5000';
        } else {
          // Desktop (Windows, Mac, Linux)
          developer.log(
              'Using default backend URL for Desktop: http://localhost:5000');
          return 'http://localhost:5000';
        }
      } catch (e) {
        // Platform not available (shouldn't happen, but fallback)
        developer.log(
            'Platform detection failed, using fallback: http://localhost:5000');
        return 'http://localhost:5000';
      }
    }
  }

  /// Get OpenRouter API key from environment variables
  /// Get your free API key from: https://openrouter.ai/keys
  /// Make sure to load .env file in main.dart before using this
  static String get openRouterApiKey {
    // Check if dotenv is initialized
    if (!dotenv.isInitialized) {
      throw Exception(
        'Environment variables not loaded. Make sure .env file exists and is loaded in main.dart',
      );
    }

    final key = dotenv.env['OPENROUTER_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      // Debug: Print all available keys
      developer.log('Available env keys: ${dotenv.env.keys.toList()}');
      throw Exception(
        'OPENROUTER_API_KEY not found in .env file. '
        'Get your free API key from: https://openrouter.ai/keys',
      );
    }
    return key;
  }

  /// Get the AI model to use (default: openai/gpt-oss-120b:free)
  /// You can override this in .env file with: OPENROUTER_MODEL=your_model
  ///
  /// Free models for educational apps:
  /// - openai/gpt-oss-120b:free - Free, open-source GPT model (requires data policy config)
  /// - google/gemini-pro - Excellent for education, free tier (no config needed)
  /// - openai/gpt-3.5-turbo - Very reliable, good free tier (no config needed)
  /// - meta-llama/llama-3.2-3b-instruct:free - Completely free, smaller but effective
  ///
  /// NOTE: If you get "data policy" error, either:
  /// 1. Configure at https://openrouter.ai/settings/privacy
  /// 2. Or use a different model like google/gemini-pro
  static String get openRouterModel {
    if (!dotenv.isInitialized) {
      return 'openai/gpt-oss-120b:free'; // Default model
    }
    return dotenv.env['OPENROUTER_MODEL']?.trim() ?? 'openai/gpt-oss-120b:free';
  }

  /// Legacy: Get Gemini API key (deprecated - use OpenRouter instead)
  @Deprecated('Use openRouterApiKey instead')
  static String get geminiApiKey {
    return openRouterApiKey;
  }

  /// Legacy: Get OpenAI API key (deprecated - use OpenRouter instead)
  @Deprecated('Use openRouterApiKey instead')
  static String? get openAiApiKey {
    return dotenv.env['OPENAI_API_KEY'];
  }
}
