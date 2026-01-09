import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/question_type.dart';
import '../services/quiz_api_service.dart';
import '../services/auth_service.dart';
import '../widgets/question_card.dart';
import '../widgets/mcq_widget.dart';
import '../widgets/true_false_widget.dart';
import '../widgets/essay_widget.dart';
import '../widgets/short_answer_widget.dart';
import '../utils/app_theme.dart';
import 'QuizResultsPage.dart';

class QuizGeneratorPage extends StatefulWidget {
  final String? documentId;
  final String? documentTitle;
  final String? initialNotes;
  final String? extractedText;
  final bool autoGenerate;
  final int? totalQuestions;
  final int? mcqCount;
  final int? trueFalseCount;
  final int? essayCount;
  final int? shortAnswerCount;
  final List<Question>? preloadedQuestions;
  final Map<String, dynamic>? preloadedResults;

  const QuizGeneratorPage({
    super.key,
    this.documentId,
    this.documentTitle,
    this.initialNotes,
    this.extractedText,
    this.autoGenerate = false,
    this.totalQuestions,
    this.mcqCount,
    this.trueFalseCount,
    this.essayCount,
    this.shortAnswerCount,
    this.preloadedQuestions,
    this.preloadedResults,
  });

  @override
  State<QuizGeneratorPage> createState() => _QuizGeneratorPageState();
}

class _QuizGeneratorPageState extends State<QuizGeneratorPage> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _docIdController = TextEditingController();
  final QuizApiService _api = QuizApiService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isSavingQuiz = false;
  List<Question> _questions = [];
  int _currentIndex = 0;
  Map<String, dynamic>? _quizResults;

  @override
  void initState() {
    super.initState();

    if (widget.preloadedQuestions != null &&
        widget.preloadedQuestions!.isNotEmpty) {
      _questions = widget.preloadedQuestions!;

      if (widget.preloadedResults != null) {
        _quizResults = widget.preloadedResults;
      }
    }

    final docId = widget.documentId;
    if (docId != null && docId.trim().isNotEmpty) {
      _docIdController.text = docId;
    }

    final textToUse = widget.extractedText ?? widget.initialNotes;
    if (textToUse != null && textToUse.trim().isNotEmpty) {
      _notesController.text = textToUse;

      if (widget.autoGenerate && widget.preloadedQuestions == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _generateQuiz();
        });
      }
    }
  }

  Future<void> _generateQuiz() async {
    if (_notesController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _quizResults = null;
    });
    try {
      _questions = await _api.generateQuiz(
        _notesController.text,
        totalQuestions: widget.totalQuestions,
        mcqCount: widget.mcqCount,
        trueFalseCount: widget.trueFalseCount,
        essayCount: widget.essayCount,
        shortAnswerCount: widget.shortAnswerCount,
      );
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
      if (question.type == QuestionType.mcq) {
        final index = question.options.indexOf(answer);
        if (index >= 0) {
          question.selectedIndex = index;
        }
      }
    });
  }

  String get _effectiveDocumentId {
    final externalId = widget.documentId;
    if (externalId != null && externalId.trim().isNotEmpty) {
      return externalId.trim();
    }
    return _docIdController.text.trim();
  }

  Future<void> _submitQuiz() async {
    final unansweredQuestions = _questions
        .where((q) => q.userAnswer == null || q.userAnswer!.isEmpty)
        .toList();

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

      if (!mounted) return;

      final quizName = widget.documentTitle ?? 'Quiz Results';

      final shouldSave = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultsPage(
            quizName: quizName,
            questions: _questions,
            quizResults: results,
          ),
        ),
      );

      if (shouldSave == true && mounted) {
        _saveQuizToDatabase();
      }
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

  Future<void> _saveQuizToDatabase() async {
    if (_questions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate a quiz before saving.')),
      );
      return;
    }

    if (_quizResults == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please submit the quiz first before saving.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final documentId = _effectiveDocumentId;
    if (documentId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No document selected. Open the quiz generator from a document to save it.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authToken = await AuthService().getAuthToken();
    if (authToken == null || authToken.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before saving quizzes to the database.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to get quiz name from user
    final quizName = await _showQuizNameDialog();
    if (quizName == null || quizName.isEmpty) {
      return;
    }

    setState(() => _isSavingQuiz = true);

    try {
      // Save the quiz WITH user answers included
      await _api.saveQuizToDatabase(
        documentId: documentId,
        name: quizName,
        questions: _questions,
        quizResults: _quizResults!,
        authToken: authToken,
      );

      print('✅ Quiz saved with user answers!');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz "$quizName" saved successfully!')),
      );
    } catch (e) {
      print('❌ Error saving quiz: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quiz: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingQuiz = false);
      }
    }
  }

  Future<String?> _showQuizNameDialog() async {
    final TextEditingController nameController = TextEditingController();
    nameController.text = widget.documentTitle ?? 'My Quiz';

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
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
                  Icons.save,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Save Quiz'),
            ],
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quiz Name',
              hintText: 'Enter a name for this quiz',
              prefixIcon: Icon(Icons.quiz, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(nameController.text),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetQuiz() {
    setState(() {
      _questions = [];
      _quizResults = null;
      _currentIndex = 0;
      // Don't clear _notesController - we want to keep the text to generate another quiz
    });
    
    // Automatically generate a new quiz if we have text
    if (_notesController.text.isNotEmpty) {
      _generateQuiz();
    }
  }

  Widget _buildQuestionContent(Question question) {
    switch (question.type) {
      case QuestionType.mcq:
        return McqWidget(
          question: question,
          onAnswerSelected: (answer) => _updateAnswer(question, answer),
        );
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          question: question,
          onAnswerSelected: (answer) => _updateAnswer(question, answer),
        );
      case QuestionType.shortAnswer:
        return ShortAnswerWidget(
          question: question,
          onAnswerChanged: (answer) => _updateAnswer(question, answer),
        );
      case QuestionType.essay:
        return EssayWidget(
          question: question,
          onAnswerChanged: (answer) => _updateAnswer(question, answer),
        );
      default:
        return const Text("Unknown question type");
    }
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

  IconData _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.toggle_on;
      case QuestionType.shortAnswer:
        return Icons.short_text;
      case QuestionType.essay:
        return Icons.article;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildResultsView() {
    final totalQuestions = _questions.length;
    final correctAnswers = _quizResults?['correctAnswers'] as int? ?? 0;
    final score = _quizResults?['score'] as int? ?? 0;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
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
                  const Text(
                    'Quiz Complete!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.percent, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$score%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Score',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$correctAnswers/$totalQuestions',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Correct',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isSavingQuiz ? null : _saveQuizToDatabase,
            icon: _isSavingQuiz
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSavingQuiz ? 'Saving...' : 'Save Quiz'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary, width: 2),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _resetQuiz,
            icon: const Icon(Icons.refresh),
            label: const Text('Take Another Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExternalDocumentId = widget.documentId?.trim().isNotEmpty == true;
    final hasExtractedText = widget.extractedText?.trim().isNotEmpty == true;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          widget.documentTitle != null
              ? "Quiz – ${widget.documentTitle}"
              : "Quiz Generator",
        ),
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
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Document ID field
          if (!hasExternalDocumentId)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _docIdController,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Document ID',
                  labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                  hintText: 'Enter the document ID to attach this quiz',
                  hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.description, color: scheme.primary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest
                      .withOpacity(isDark ? 0.3 : 0.7),
                ),
              ),
            ),

          // Notes text field
          if (!hasExtractedText) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notesController,
                maxLines: 5,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Paste your notes here...",
                  hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withOpacity(0.6)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.note_add, color: scheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.error),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest
                      .withOpacity(isDark ? 0.3 : 0.7),
                ),
              ),
            ),

            // Generate Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateQuiz,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(
                    _isLoading ? "Generating..." : "Generate Quiz",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],

          // Loading indicator
          if (_isLoading && hasExtractedText)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.accent.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Generating quiz from document...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few moments',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Question UI or Results
          if (!_isLoading || !hasExtractedText)
            Expanded(
              child: _quizResults != null
                  ? SingleChildScrollView(child: _buildResultsView())
                  : _questions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.1),
                                      AppColors.accent.withOpacity(0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.quiz,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hasExtractedText
                                    ? "Generating quiz..."
                                    : "Enter your notes to generate quiz",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildEnhancedQuestionCard(),
            ),

          // Navigation and Submit Buttons
          if (_questions.isNotEmpty && _quizResults == null) ...[
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _questions.length,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_currentIndex + 1}/${_questions.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Previous"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: _currentIndex > 0
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentIndex < _questions.length - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Next"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: _currentIndex < _questions.length - 1
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Submit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitQuiz,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    _isSubmitting ? "Submitting..." : "Submit Quiz",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuestionCard() {
    final question = _questions[_currentIndex];
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question type badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getQuestionTypeIcon(question.type),
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getQuestionTypeLabel(question.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Answer status indicator
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: question.userAnswer != null &&
                                question.userAnswer!.isNotEmpty
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        question.userAnswer != null &&
                                question.userAnswer!.isNotEmpty
                            ? Icons.check
                            : Icons.edit,
                        size: 16,
                        color: question.userAnswer != null &&
                                question.userAnswer!.isNotEmpty
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question text
                Text(
                  question.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Answer section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Answer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuestionContent(question),
              ],
            ),
          ),
        ],
      ),
    );
  }
}