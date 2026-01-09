import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/question_type.dart';
import '../utils/app_theme.dart';

class QuizResultsPage extends StatelessWidget {
  final String quizName;
  final List<Question> questions;
  final Map<String, dynamic>? quizResults;
  final bool isViewingSavedQuiz; // When true, hide Save button

  const QuizResultsPage({
    super.key,
    required this.quizName,
    required this.questions,
    this.quizResults,
    this.isViewingSavedQuiz = false, // Default to false (showing new quiz results)
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    // Debug output
    print('📊 QuizResultsPage received:');
    print('   Quiz Name: $quizName');
    print('   Questions count: ${questions.length}');
    print('   Quiz Results: $quizResults');
    if (questions.isNotEmpty) {
      print('   First question: ${questions[0].text}');
      print('   First question options: ${questions[0].options}');
      print('   First question userAnswer: ${questions[0].userAnswer}');
    }

    // Calculate statistics
    final totalQuestions = questions.length;
    final feedbackList = quizResults?['feedback'] as List<dynamic>? ?? [];
    final correctAnswers = quizResults?['correctAnswers'] as int? ?? totalQuestions;
    final score = quizResults?['score'] as int? ?? 100;

    print('   📈 Calculated stats:');
    print('      Total Questions: $totalQuestions');
    print('      Feedback count: ${feedbackList.length}');
    print('      Correct Answers: $correctAnswers');
    print('      Score: $score%');

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(quizName),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.accent.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Results Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Trophy Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        score >= 70
                            ? Icons.emoji_events
                            : score >= 50
                                ? Icons.star
                                : Icons.lightbulb_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quiz Results Title
                    const Text(
                      'Quiz Results',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Score Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Score',
                          '$score%',
                          Icons.percent,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          'Correct',
                          '$correctAnswers/$totalQuestions',
                          Icons.check_circle,
                        ),
                      ],
                    ),

                    // Performance Message
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getPerformanceMessage(score),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Questions and Answers Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Questions & Answers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // DEBUG: Show question count
                  if (questions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.red.shade100,
                      child: Text(
                        '⚠️ NO QUESTIONS LOADED!',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✅ Loaded ${questions.length} questions',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Questions List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      // Match feedback by questionId (not just by index)
                      Map<String, dynamic>? feedback;
                      if (feedbackList.isNotEmpty) {
                        try {
                          feedback = feedbackList.firstWhere(
                            (f) => (f['questionId'] as int?) == question.id,
                          ) as Map<String, dynamic>?;
                        } catch (e) {
                          // Fallback to index-based matching if questionId doesn't match
                          if (index < feedbackList.length) {
                            feedback = feedbackList[index] as Map<String, dynamic>?;
                          }
                        }
                      }

                      return _buildQuestionCard(
                        context,
                        question,
                        index + 1,
                        feedback,
                        isDark,
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isViewingSavedQuiz
          ? // When viewing saved quiz, only show Back button
          FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              backgroundColor: AppColors.primary,
            )
          : // When viewing new quiz results, show Save and Back buttons
          Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Save Quiz Button
                FloatingActionButton.extended(
                  onPressed: () => Navigator.pop(context, true), // Return true to trigger save
                  icon: const Icon(Icons.save),
                  label: const Text('Save Quiz'),
                  backgroundColor: Colors.green,
                  heroTag: 'save',
                ),
                const SizedBox(height: 12),
                // Back Button
                FloatingActionButton.extended(
                  onPressed: () => Navigator.pop(context, false), // Return false, don't save
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  backgroundColor: AppColors.primary,
                  heroTag: 'back',
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _getPerformanceMessage(int score) {
    if (score >= 90) return '🎉 Excellent! Outstanding performance!';
    if (score >= 80) return '⭐ Great job! Well done!';
    if (score >= 70) return '👍 Good work! Keep it up!';
    if (score >= 60) return '📚 Not bad! Room for improvement.';
    return '💪 Keep practicing! You\'ll get there!';
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Question question,
    int questionNumber,
    Map<String, dynamic>? feedback,
    bool isDark,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isCorrect = feedback?['isCorrect'] as bool? ?? true;
    final correctAnswer = feedback?['correctAnswer'] as String? ?? question.userAnswer;
    final feedbackText = feedback?['feedback'] as String? ?? 'Correct answer: $correctAnswer';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Number Badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Question Text
                Expanded(
                  child: Text(
                    question.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),

                // Correct/Incorrect Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Question Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getQuestionTypeLabel(question.type),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // User's Answer (for Short Answer and Essay)
            if ((question.type == QuestionType.shortAnswer || question.type == QuestionType.essay) &&
                question.userAnswer != null && question.userAnswer!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.userAnswer!,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Answer Options (for MCQ and True/False)
            if (question.type == QuestionType.mcq || question.type == QuestionType.trueFalse)
              ...question.options.map((option) {
                final isThisCorrect = option == correctAnswer;
                final wasSelected = option == question.userAnswer;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isThisCorrect
                        ? Colors.green.withOpacity(0.1)
                        : wasSelected && !isThisCorrect
                            ? Colors.red.withOpacity(0.1)
                            : scheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isThisCorrect
                          ? Colors.green
                          : wasSelected && !isThisCorrect
                              ? Colors.red
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isThisCorrect)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      else if (wasSelected)
                        const Icon(Icons.cancel, color: Colors.red, size: 20)
                      else
                        Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isThisCorrect ? FontWeight.bold : FontWeight.normal,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (isThisCorrect)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Correct',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),

            // Correct Answer (for Short Answer and Essay when available)
            if ((question.type == QuestionType.shortAnswer || question.type == QuestionType.essay) &&
                correctAnswer != null && 
                correctAnswer.isNotEmpty &&
                correctAnswer != question.userAnswer) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Correct Answer:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      correctAnswer,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Feedback Section
            if (feedbackText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedbackText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.essay:
        return 'Essay';
      default:
        return 'Question';
    }
  }
}