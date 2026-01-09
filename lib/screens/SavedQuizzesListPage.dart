import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/QuizService.dart';
import '../models/question.dart';
import '../models/question_type.dart';
import 'QuizResultsPage.dart';

class SavedQuizzesListPage extends StatefulWidget {
  final bool showRecentsOnly;
  final String? documentId; // NEW: Optional document ID to filter quizzes

  const SavedQuizzesListPage({
    super.key,
    this.showRecentsOnly = false,
    this.documentId, // NEW: Add document ID parameter
  });

  @override
  State<SavedQuizzesListPage> createState() => _SavedQuizzesListPageState();
}

class _SavedQuizzesListPageState extends State<SavedQuizzesListPage> {
  final QuizService _quizService = QuizService();
  List<SavedQuiz> _quizzes = [];
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date' or 'name'

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<SavedQuiz> quizzes;
      
      // NEW: Check if we should filter by document ID
      if (widget.documentId != null) {
        // Fetch quizzes for specific document
        quizzes = await _quizService.getQuizzesByDocument(widget.documentId!);
      } else if (widget.showRecentsOnly) {
        quizzes = await _quizService.getRecentQuizzes(limit: 10);
      } else {
        quizzes = await _quizService.getAllQuizzes();
      }

      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load quizzes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuizzes = _quizzes.where((quiz) {
      return quiz.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort quizzes
    filteredQuizzes.sort((a, b) {
      if (_sortBy == 'date') {
        return b.dateCreated.compareTo(a.dateCreated);
      } else {
        return a.name.compareTo(b.name);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Gradient Icon Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Title with gradient text effect
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.accent,
                  ],
                ).createShader(bounds),
                child: Text(
                  widget.documentId != null
                      ? 'Document Quizzes'
                      : widget.showRecentsOnly
                          ? 'Recent Quizzes'
                          : 'My Quizzes',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
        actions: [
          // Enhanced Sort Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.filter_list_rounded,
                color: AppColors.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _sortBy == 'date' 
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.event_rounded,
                          size: 20,
                          color: _sortBy == 'date' 
                              ? AppColors.primary 
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sort by Date',
                        style: TextStyle(
                          fontWeight: _sortBy == 'date' 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: _sortBy == 'date' 
                              ? AppColors.primary 
                              : null,
                        ),
                      ),
                      if (_sortBy == 'date') ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _sortBy == 'name' 
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.sort_by_alpha_rounded,
                          size: 20,
                          color: _sortBy == 'name' 
                              ? AppColors.primary 
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sort by Name',
                        style: TextStyle(
                          fontWeight: _sortBy == 'name' 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: _sortBy == 'name' 
                              ? AppColors.primary 
                              : null,
                        ),
                      ),
                      if (_sortBy == 'name') ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.accent.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search quizzes...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Quiz Count Badge
          if (filteredQuizzes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.accent.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${filteredQuizzes.length} ${filteredQuizzes.length == 1 ? 'quiz' : 'quizzes'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Quiz List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading quizzes...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredQuizzes.isEmpty
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
                                    AppColors.accent.withOpacity(0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.quiz_outlined,
                                size: 64,
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No quizzes yet'
                                  : 'No quizzes found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Create your first quiz to get started'
                                  : 'Try searching for something else',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadQuizzes,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = filteredQuizzes[index];
                            return _buildQuizCard(quiz);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// UPDATED: View quiz with proper attempt data handling
  // In SavedQuizzesListPage.dart - Update the _viewQuiz method

Future<void> _viewQuiz(SavedQuiz quiz) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading quiz...'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    // Fetch quiz details with questions AND attempts
    final quizDetails = await _quizService.getQuizDetails(quiz.id);

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    print('📦 Quiz Details received:');
    print('   Keys: ${quizDetails.keys.toList()}');
    print('   Full data: ${quizDetails.toString()}');

    final questionsData = quizDetails['questions'] as List<dynamic>? ?? [];
    final attempt = quizDetails['attempt'] as Map<String, dynamic>?;
    final questionAttempts = quizDetails['questionAttempts'] as List<dynamic>? ?? [];

    print('   Questions: ${questionsData.length}');
    print('   Attempt: ${attempt != null ? 'Found - $attempt' : 'Not found'}');
    print('   Question Attempts: ${questionAttempts.length}');
    
    if (questionAttempts.isNotEmpty) {
      print('   First question attempt: ${questionAttempts[0]}');
    }

    final questions = <Question>[];
    final feedbackList = <Map<String, dynamic>>[];
    int correctCount = 0;

    // Process questions with attempt data if available
    if (attempt != null && questionAttempts.isNotEmpty) {
      print('   ✅ Using attempt data to reconstruct quiz results');
      
      for (var i = 0; i < questionsData.length; i++) {
        final q = questionsData[i];
        final questionId = q['question_id'] as String?;
        
        // Find corresponding attempt for this question
        // Try to match by question_id (handle both string and int comparisons)
        Map<String, dynamic>? questionAttempt;
        try {
          questionAttempt = questionAttempts.firstWhere(
            (qa) {
              final qaQuestionId = qa['question_id']?.toString();
              final qQuestionId = questionId?.toString();
              final match = qaQuestionId == qQuestionId;
              if (match) {
                print('      ✅ Matched question attempt for question_id: $questionId');
              }
              return match;
            },
          ) as Map<String, dynamic>?;
        } catch (e) {
          // No matching attempt found for this question
          questionAttempt = null;
          print('      ⚠️ No attempt found for question_id: $questionId');
          print('      Available question_ids in attempts: ${questionAttempts.map((qa) => qa['question_id']?.toString()).toList()}');
        }
        
        final answers = q['answers'] as List<dynamic>? ?? [];
        
        print('   Question ${i + 1}: ${q['text']}');
        print('      Answers: ${answers.length}');
        
        QuestionType questionType = QuestionType.essay;
        List<String> options = [];
        
        if (answers.length == 2) {
          questionType = QuestionType.trueFalse;
          options = ['True', 'False'];
        } else if (answers.length >= 3) {
          questionType = QuestionType.mcq;
          options = answers.map((a) => a['text'] as String? ?? '').toList();
        }
        
       // Find which answer the user selected
String? userAnswer;
String? correctAnswer;

for (var answer in answers) {
  // Check if this answer was selected by user
  final wasSelected = answer['user_selected'] as bool? ?? false;
  if (wasSelected) {
    userAnswer = answer['text'] as String?;
  }
  
  // Check if this is the correct answer
  final isCorrect = answer['is_correct'] as bool? ?? false;
  if (isCorrect) {
    correctAnswer = answer['text'] as String?;
  }
}

// Build feedback
final isAnswerCorrect = (userAnswer == correctAnswer) && correctAnswer != null;

feedbackList.add({
  'questionId': i + 1,
  'isCorrect': isAnswerCorrect,
  'correctAnswer': correctAnswer ?? '',
  'userAnswer': userAnswer ?? '',
  'feedback': isAnswerCorrect
      ? 'Correct!'
      : 'Incorrect. You answered: ${userAnswer ?? "None"}. Correct answer: ${correctAnswer ?? "Not specified"}',
});

questions.add(Question(
  id: i + 1,
  text: q['text'] as String? ?? '',
  type: questionType,
  options: options,
  userAnswer: userAnswer, // ← Set the user's answer
));
        
        // Set selectedIndex for MCQ questions
        int? selectedIndex;
        if (questionType == QuestionType.mcq && userAnswer != null && options.isNotEmpty) {
          final index = options.indexOf(userAnswer);
          if (index >= 0) {
            selectedIndex = index;
          }
        }
        
        questions.add(Question(
          id: i + 1,
          text: q['text'] as String? ?? '',
          type: questionType,
          options: options,
          userAnswer: userAnswer,
          selectedIndex: selectedIndex,
        ));
      }
    
      // REPLACE THE ENTIRE ELSE BLOCK (starting around line 630-680)
// This is the section that handles when there's no attempt data

} else {
  // No attempt data - check if user answers are saved in Answer table
  print('   ⚠️ No attempt data found - checking for user_selected in answers');
  
  for (var i = 0; i < questionsData.length; i++) {
    final q = questionsData[i];
    final answers = q['answers'] as List<dynamic>? ?? [];
    
    print('   📝 Question ${i + 1}: ${q['text']}');
    print('      Answers count: ${answers.length}');
    
    QuestionType questionType = QuestionType.essay;
    List<String> options = [];
    
    if (answers.length == 2) {
      questionType = QuestionType.trueFalse;
      options = ['True', 'False'];
    } else if (answers.length >= 3) {
      questionType = QuestionType.mcq;
      options = answers.map((a) => a['text'] as String? ?? '').toList();
    }
    
    // Check BOTH is_correct AND user_selected
    String? correctAnswer;
    String? userAnswer;
    
    for (var j = 0; j < answers.length; j++) {
      final answer = answers[j];
      final answerText = answer['text'] as String? ?? '';
      
      // Check if this is the correct answer
      final isCorrect = answer['is_correct'] ?? answer['isCorrect'] ?? false;
      if (isCorrect == true) {
        correctAnswer = answerText;
      }
      
      // ⭐ CHECK IF THIS WAS SELECTED BY USER ⭐
      final userSelected = answer['user_selected'] ?? answer['userSelected'] ?? false;
      if (userSelected == true) {
        userAnswer = answerText;
        print('      👤 USER SELECTED: $answerText');
      }
      
      print('      Answer ${j + 1}: "$answerText"');
      print('         is_correct: $isCorrect');
      print('         user_selected: $userSelected');
    }
    
    if (correctAnswer != null) {
      print('      ✅ CORRECT ANSWER: $correctAnswer');
    }
    if (userAnswer != null) {
      print('      👤 USER ANSWER: $userAnswer');
    }
    
    // Determine if user got it right
    final isAnswerCorrect = (userAnswer != null && userAnswer == correctAnswer);
    
    feedbackList.add({
      'questionId': i + 1,
      'isCorrect': isAnswerCorrect,
      'correctAnswer': correctAnswer ?? '',
      'userAnswer': userAnswer ?? '',
      'feedback': userAnswer != null
          ? (isAnswerCorrect
              ? 'Correct!'
              : 'Incorrect. You answered: $userAnswer. Correct answer: ${correctAnswer ?? "Not specified"}')
          : 'This quiz has not been taken yet. The correct answer is: ${correctAnswer ?? "Not specified"}',
    });
    
    if (isAnswerCorrect) correctCount++;
    
    questions.add(Question(
      id: i + 1,
      text: q['text'] as String? ?? '',
      type: questionType,
      options: options,
      userAnswer: userAnswer, // ⭐ THIS IS THE KEY - SET THE USER'S ANSWER ⭐
    ));
  }
}

    // Reconstruct quiz results for display
    // Use actual attempt score if available, otherwise calculate from correct answers
    int score;
    if (attempt != null && attempt['score'] != null) {
      score = (attempt['score'] as num).toInt();
      print('   📊 Using score from attempt: $score%');
    } else {
      score = questions.isEmpty ? 0 : ((correctCount / questions.length) * 100).round();
      print('   📊 Calculated score from correct answers: $score%');
    }
    
    final mockQuizResults = {
      'score': score,
      'totalQuestions': questions.length,
      'correctAnswers': correctCount,
      'feedback': feedbackList,
    };

    print('📊 Final Results:');
    print('   Questions: ${questions.length}');
    print('   Correct: $correctCount');
    print('   Score: ${mockQuizResults['score']}%');

    // Navigate to QuizResultsPage
    // Pass isViewingSavedQuiz=true to hide the Save button
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultsPage(
            quizName: quiz.name,
            questions: questions,
            quizResults: mockQuizResults,
            isViewingSavedQuiz: true, // Hide Save button when viewing saved quiz
          ),
        ),
      );
    }
  } catch (e) {
    // Close loading dialog if still open
    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load quiz: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void _showQuizOptions(BuildContext context, SavedQuiz quiz) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Take Quiz'),
            onTap: () async {
              Navigator.pop(context);

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading quiz...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                // Fetch quiz details with questions
                final quizDetails =
                    await _quizService.getQuizDetails(quiz.id);

                // Close loading dialog
                if (mounted) {
                  Navigator.pop(context);
                }

                // TODO: Navigate to quiz taking page with the questions
                // You'll need to create a QuizTakingPage that displays the quiz
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Quiz loaded! (Navigate to quiz taking page here)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog if still open
                if (mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to load quiz: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to quiz details/preview page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quiz details page coming soon!'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteQuiz(quiz);
            },
          ),
        ],
      ),
    );
  }

  void _deleteQuiz(SavedQuiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _quizService.deleteQuiz(quiz.id);
                await _loadQuizzes();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quiz deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete quiz: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(SavedQuiz quiz) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewQuiz(quiz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Gradient Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.accent,
                    ],
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
                child: const Icon(
                  Icons.quiz_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Quiz Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz Title
                    Text(
                      quiz.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Date and Question Count Row
                    Row(
                      children: [
                        // Date with colored icon
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(quiz.dateCreated),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Question Count with colored icon
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quiz.questionCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Document Name (if available)
                    if (quiz.documentName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              quiz.documentName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons (replacing 3-dot menu)
              // Delete Button Only
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22,
                  ),
                  onPressed: () => _deleteQuiz(quiz),
                  padding: EdgeInsets.zero,
                  tooltip: 'Delete Quiz',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Format time as HH:MM AM/PM
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $period';

    if (difference.inDays == 0) {
      return 'Today $timeString';
    } else if (difference.inDays == 1) {
      return 'Yesterday $timeString';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}