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
    this.model = 'openai/gpt-oss-120b:free', // Default model
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
    final systemPrompt =
        '''You are an AI study assistant specialized in creating comprehensive summaries for educational content. 
Your summaries should be clear, well-structured, and highlight key concepts, important points, and practical applications.''';

    final userPrompt = documentContent != null
        ? '''Please provide a comprehensive summary of the following document titled "${documentTitle}":
        
$documentContent

Include:
- Key points and main concepts
- Important definitions or formulas
- Practical applications
- Study recommendations'''
        : '''Please provide a summary for the document "${documentTitle}". 
${context != null ? 'Context: $context' : 'Generate a general summary structure that would be helpful for studying this topic.'}''';

    return await chat(
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
      systemPrompt: systemPrompt,
      temperature: 0.5,
    );
  }

  /// Generate MCQ questions
  Future<String> generateMCQ({
    required String documentTitle,
    String? documentContent,
    int numQuestions = 5,
  }) async {
    final systemPrompt =
        '''You are an AI tutor that creates high-quality multiple-choice questions for educational purposes.
Generate questions that test understanding, not just memorization. Include 4 options (A, B, C, D) and clearly indicate the correct answer.''';

    final userPrompt = documentContent != null
        ? '''Based on the following document "${documentTitle}", generate $numQuestions multiple-choice questions:
        
$documentContent

Format each question as:
**Question X:**
[Question text]
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
**Answer:** [Correct option]'''
        : '''Generate $numQuestions multiple-choice questions based on the document "${documentTitle}".
Format each question with 4 options (A, B, C, D) and indicate the correct answer.''';

    return await chat(
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
      systemPrompt: systemPrompt,
      temperature: 0.8,
    );
  }

  /// Explain a concept
  Future<String> explainConcept({
    required String concept,
    String? documentContext,
    String? documentTitle,
  }) async {
    final systemPrompt =
        '''You are an AI tutor that explains concepts clearly and comprehensively.
Break down complex ideas into understandable parts, use examples, and relate concepts to practical applications.''';

    final userPrompt = documentContext != null
        ? '''Explain the concept "${concept}" based on the following context from "${documentTitle}":
        
$documentContext

Provide:
1. A clear definition
2. Key components or principles
3. Examples and applications
4. How it relates to other concepts'''
        : '''Explain the concept "${concept}" in detail. Provide a clear definition, key components, examples, and practical applications.''';

    return await chat(
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
      systemPrompt: systemPrompt,
      temperature: 0.7,
    );
  }

  /// Generate study notes
  Future<String> generateStudyNotes({
    required String documentTitle,
    String? documentContent,
  }) async {
    final systemPrompt =
        '''You are an AI study assistant that creates organized, effective study notes.
Structure notes with clear headings, bullet points, key definitions, and important formulas.''';

    final userPrompt = documentContent != null
        ? '''Create comprehensive study notes for "${documentTitle}":
        
$documentContent

Include:
- Main topics and subtopics
- Key definitions and formulas
- Important examples
- Study tips and mnemonics'''
        : '''Create study notes structure for "${documentTitle}". Include main topics, key points, definitions, and study recommendations.''';

    return await chat(
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
      systemPrompt: systemPrompt,
      temperature: 0.6,
    );
  }

  /// General chat for tutoring
  Future<String> tutorChat({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
    String? documentTitle,
    String? documentContext,
  }) async {
    final systemPrompt =
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
