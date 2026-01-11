import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenRouter Service - Unified API for multiple AI models
/// Get your free API key from: https://openrouter.ai/keys
///
/// Free models for educational apps:
/// - "openai/gpt-oss-120b:free" - Free, open-source GPT model (DEFAULT)
/// - "google/gemini-pro" - Excellent for education, free tier
/// - "openai/gpt-3.5-turbo" - Very reliable, good free tier
/// - "meta-llama/llama-3.2-3b-instruct:free" - Completely free, smaller but effective
class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  final String apiKey;
  final String model;

  OpenRouterService({
    required this.apiKey,
    this.model = 'google/gemini-3-flash-preview-20251217', // Default model
  });

  /// Send a chat message and get AI response
  /// Uses OpenAI-compatible format
  Future<String> chat({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      // Build messages array in OpenAI format
      final List<Map<String, dynamic>> formattedMessages = [];

      // Add system prompt if provided
      if (systemPrompt != null) {
        formattedMessages.add({'role': 'system', 'content': systemPrompt});
      }

      // Add conversation messages
      for (var msg in messages) {
        formattedMessages.add({
          'role': msg['role'] == 'user' ? 'user' : 'assistant',
          'content': msg['content'],
        });
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer':
              'https://github.com/yourusername/eduscript', // Optional: your app URL
          'X-Title': 'EduScript', // Optional: your app name
        },
        body: jsonEncode({
          'model': model,
          'messages': formattedMessages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] as String;
        } else {
          throw Exception('No response generated');
        }
      } else {
        final errorBody = response.body;
        try {
          final error = jsonDecode(errorBody);
          final errorMessage = error['error']?['message'] ?? '';
          final errorCode = error['error']?['code'];

          // Handle specific error cases
          if (errorMessage.contains('data policy') ||
              errorMessage.contains('Free model publication')) {
            throw Exception(
              'Data Policy Error: $errorMessage\n\n'
              'Please configure your OpenRouter account:\n'
              '1. Go to: https://openrouter.ai/settings/privacy\n'
              '2. Enable "Free model publication" or adjust your data policy settings\n'
              '3. Try again after saving your settings',
            );
          }

          throw Exception(
            errorMessage.isNotEmpty
                ? errorMessage
                : (errorCode != null
                    ? 'Error $errorCode'
                    : 'Failed to get response from OpenRouter'),
          );
        } catch (e) {
          // If it's already our custom exception, rethrow it
          if (e.toString().contains('Data Policy Error')) {
            rethrow;
          }
          throw Exception(
            'Failed to get response: ${response.statusCode} - $errorBody',
          );
        }
      }
    } catch (e) {
      throw Exception('Error communicating with OpenRouter: $e');
    }
  }

  /// Generate a summary for a document
  Future<String> generateSummary({
    required String documentTitle,
    String? documentContent,
    String? context,
  }) async {
    const systemPrompt =
        '''You are an expert academic assistant specialized in creating clear, concise, and comprehensive summaries of educational documents. 
Your goal is to help students understand and retain key information from their study materials.

IMPORTANT: You must return the summary in a structured JSON format that clearly identifies different content types. This allows the app to properly format and display the summary.

Return the summary as a JSON object with this exact structure:
{
  "sections": [
    {
      "type": "heading",
      "text": "Main Title or Section Heading"
    },
    {
      "type": "paragraph",
      "text": "Paragraph content here..."
    },
    {
      "type": "list",
      "items": ["Item 1", "Item 2", "Item 3"]
    },
    {
      "type": "heading",
      "text": "Another Section"
    },
    {
      "type": "paragraph",
      "text": "More paragraph content..."
    }
  ]
}

Content types:
- "heading": For titles, section headers, main topics (should be short, descriptive)
- "paragraph": For regular text content, explanations, descriptions
- "list": For bullet points, key points, numbered items

Guidelines:
- Create a well-structured summary that captures the essence of the document
- Focus on main concepts, key points, and important details
- Use clear, academic language
- Organize information logically with proper headings and sections
- Highlight definitions, formulas, and critical information
- Make it easy to read and study from
- Keep it comprehensive but concise
- Return ONLY valid JSON, no markdown, no extra text, no explanations''';

    final userPrompt = documentContent != null && documentContent.isNotEmpty
        ? '''Create a comprehensive, well-structured summary of the following document titled "$documentTitle".

Document Content:
$documentContent

Requirements:
1. Start with a brief overview paragraph of the document's main topic and purpose
2. Organize the summary into clear sections with headings
3. Include all key concepts, definitions, and important information
4. Highlight any formulas, equations, or technical terms
5. Summarize main points and supporting details
6. Make it study-friendly and easy to review
7. Use headings for main topics, paragraphs for explanations, and lists for key points
8. Ensure the summary is comprehensive enough to be useful for studying

Return the summary as a JSON object following the exact structure specified. Use "heading" for titles/sections, "paragraph" for regular text, and "list" for bullet points. Return ONLY the JSON object, nothing else.'''
        : '''Please provide a summary for the document "$documentTitle". 
${context != null ? 'Context: $context' : 'Generate a general summary structure that would be helpful for studying this topic.'}

Return the summary as a JSON object following the exact structure: {"sections": [{"type": "heading|paragraph|list", "text": "..." or "items": [...]}]}. Return ONLY the JSON object, nothing else.''';
    final stopwatch = Stopwatch()..start();

    try {
      final result = await chat(
        messages: [
          {'role': 'user', 'content': userPrompt},
        ],
        systemPrompt: systemPrompt,
        temperature: 0.3,
        maxTokens: 4000,
      );

      stopwatch.stop();
      print('Model "$model" finished in ${stopwatch.elapsedMilliseconds} ms');

      return result;
    } catch (e) {
      stopwatch.stop();
      print('Model "$model" failed after ${stopwatch.elapsedMilliseconds} ms');
      rethrow;
    }
  }

  /// General chat for tutoring
  Future<String> tutorChat({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
    String? documentTitle,
    String? documentContext,
  }) async {
    const systemPrompt =
        '''You are an AI study tutor and assistant. You help students understand concepts, 
create summaries, generate study materials, and answer questions about their course content. 
Be friendly, encouraging, and educational. Break down complex topics into understandable parts.''';

    final List<Map<String, String>> messages = [];

    // Add document context to system prompt if provided
    String fullSystemPrompt = systemPrompt;
    if (documentTitle != null) {
      fullSystemPrompt +=
          '\n\nThe user is asking about the document: "$documentTitle".';
      if (documentContext != null) {
        fullSystemPrompt += '\nDocument context: $documentContext';
      }
    }

    // Add conversation history
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      messages.addAll(conversationHistory);
    }

    // Add current user message
    messages.add({'role': 'user', 'content': userMessage});

    return await chat(
      messages: messages,
      systemPrompt: fullSystemPrompt,
      temperature: 0.7,
    );
  }
}
