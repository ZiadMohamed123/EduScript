import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/question_type.dart';
import '../services/quiz_api_service.dart';
import '../widgets/question_card.dart';
import '../widgets/mcq_widget.dart';
import '../widgets/true_false_widget.dart';
import '../widgets/essay_widget.dart';
import '../widgets/short_answer_widget.dart';

class QuizGeneratorPage extends StatefulWidget {
  const QuizGeneratorPage({super.key});

  @override
  State<QuizGeneratorPage> createState() => _QuizGeneratorPageState();
}

class _QuizGeneratorPageState extends State<QuizGeneratorPage> {
  final TextEditingController _notesController = TextEditingController();
  final QuizApiService _api = QuizApiService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Question> _questions = [];
  int _currentIndex = 0;
  Map<String, dynamic>? _quizResults;

  Future<void> _generateQuiz() async {
    if (_notesController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _quizResults = null; // Reset results when generating new quiz
    });
    try {
      _questions = await _api.generateQuiz(_notesController.text);
      _currentIndex = 0;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating quiz: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateAnswer(Question question, String answer) {
    setState(() {
      question.userAnswer = answer;
      // For MCQ, also store the selected index
      if (question.type == QuestionType.mcq) {
        final index = question.options.indexOf(answer);
        if (index >= 0) {
          question.selectedIndex = index;
        }
      }
    });
  }

  Future<void> _submitQuiz() async {
    // Check if all questions are answered
    final unansweredQuestions = _questions.where((q) => 
      q.userAnswer == null || q.userAnswer!.isEmpty
    ).toList();

    if (unansweredQuestions.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final results = await _api.submitQuiz(_questions);
      setState(() {
        _quizResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting quiz: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetQuiz() {
    setState(() {
      _questions = [];
      _currentIndex = 0;
      _quizResults = null;
      _notesController.clear();
    });
  }

  Widget _buildQuestionContent(Question q) {
    switch (q.type) {
      case QuestionType.mcq:
        return McqWidget(
          options: q.options,
          initialAnswer: q.userAnswer,
          onAnswerChanged: (answer) => _updateAnswer(q, answer),
        );
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          initialAnswer: q.userAnswer,
          onAnswerChanged: (answer) => _updateAnswer(q, answer),
        );
      case QuestionType.essay:
        return EssayWidget(
          initialAnswer: q.userAnswer,
          onAnswerChanged: (answer) => _updateAnswer(q, answer),
        );
      case QuestionType.shortAnswer:
        return ShortAnswerWidget(
          initialAnswer: q.userAnswer,
          onAnswerChanged: (answer) => _updateAnswer(q, answer),
        );
    }
  }

  Widget _buildResultsView() {
    if (_quizResults == null) return const SizedBox.shrink();

    final score = _quizResults!['score'] as int;
    final totalQuestions = _quizResults!['totalQuestions'] as int;
    final correctAnswers = _quizResults!['correctAnswers'] as int;
    final feedbackList = _quizResults!['feedback'] as List<dynamic>;

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quiz Results',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: score >= 70 ? Colors.green : score >= 50 ? Colors.orange : Colors.red,
                      ),
                    ),
                    const Text('Score'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$correctAnswers / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Correct'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Feedback:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...feedbackList.map((feedback) {
              final questionId = feedback['questionId'] as int;
              final isCorrect = feedback['isCorrect'] as bool;
              final feedbackText = feedback['feedback'] as String;
              final question = _questions.firstWhere((q) => q.id == questionId);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Q${questionId}: ${question.text}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 4),
                      child: Text(
                        feedbackText,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Take Another Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text("Quiz Generator"),
        backgroundColor: const Color(0xFF0066CC),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Input Notes
Padding(
  padding: const EdgeInsets.all(16),
  child: TextField(
    controller: _notesController,
    maxLines: 5,
    decoration: InputDecoration(
      hintText: "Paste your notes here...",

      // Normal (not focused) border
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF0066CC),   // ← Change this to your color
          width: 1.5,
        ),
      ),

      // Border when the user taps the field
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.blueAccent,   // ← Focus color
          width: 2,
        ),
      ),

      // Optional: border when error occurs
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
  ),
),


          // Generate Button
          ElevatedButton(
            onPressed: _isLoading ? null : _generateQuiz,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC)),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Generate Quiz",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                ),
          ),

          const SizedBox(height: 16),

          // Question UI or Results
          Expanded(
            child: _quizResults != null
                ? SingleChildScrollView(child: _buildResultsView())
                : _questions.isEmpty
                    ? const Center(child: Text("Enter your notes to generate quiz"))
                    : QuestionCard(
                        question: _questions[_currentIndex],
                        child: _buildQuestionContent(_questions[_currentIndex]),
                      ),
          ),

          // Navigation and Submit Button
          if (_questions.isNotEmpty && _quizResults == null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                  child: const Text("Previous"),
                ),
                Text("${_currentIndex + 1} / ${_questions.length}"),
                TextButton(
                  onPressed: _currentIndex < _questions.length - 1
                      ? () => setState(() => _currentIndex++)
                      : null,
                  child: const Text("Next"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit Quiz",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
