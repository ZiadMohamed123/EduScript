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
  List<Question> _questions = [];
  int _currentIndex = 0;

  Future<void> _generateQuiz() async {
    setState(() => _isLoading = true);

    _questions = await _api.generateQuiz(_notesController.text);

    setState(() {
      _currentIndex = 0;
      _isLoading = false;
    });
  }

  Widget _buildQuestionContent(Question q) {
    switch (q.type) {
      case QuestionType.mcq:
        return McqWidget(options: q.options);
      case QuestionType.trueFalse:
        return const TrueFalseWidget();
      case QuestionType.essay:
        return const EssayWidget();
      case QuestionType.shortAnswer:
        return const ShortAnswerWidget();
    }
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

          // Question UI
          Expanded(
            child: _questions.isEmpty
                ? const Center(child: Text("Enter your notes to generate quiz"))
                : QuestionCard(
                    question: _questions[_currentIndex],
                    child: _buildQuestionContent(_questions[_currentIndex]),
                  ),
          ),

          // Navigation
          if (_questions.isNotEmpty)
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

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
