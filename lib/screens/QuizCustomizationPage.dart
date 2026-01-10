import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'quiz_generator_page.dart';

class QuizCustomizationPage extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final String extractedText;

  const QuizCustomizationPage({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.extractedText,
  });

  @override
  State<QuizCustomizationPage> createState() => _QuizCustomizationPageState();
}

class _QuizCustomizationPageState extends State<QuizCustomizationPage> {
  int _totalQuestions = 5;
  int _mcqCount = 3;
  int _trueFalseCount = 1;
  int _essayCount = 1;
  int _shortAnswerCount = 0;

  @override
  void initState() {
    super.initState();
    _updateCounts();
  }

  void _updateCounts() {
    // Ensure counts don't exceed total
    final sum = _mcqCount + _trueFalseCount + _essayCount + _shortAnswerCount;
    if (sum > _totalQuestions) {
      // Proportionally reduce counts
      final factor = _totalQuestions / sum;
      _mcqCount = (_mcqCount * factor).round();
      _trueFalseCount = (_trueFalseCount * factor).round();
      _essayCount = (_essayCount * factor).round();
      _shortAnswerCount = (_shortAnswerCount * factor).round();
      
      // Adjust for rounding errors
      final newSum = _mcqCount + _trueFalseCount + _essayCount + _shortAnswerCount;
      if (newSum < _totalQuestions) {
        _mcqCount += _totalQuestions - newSum;
      }
    }
  }

  int get _selectedTotal => _mcqCount + _trueFalseCount + _essayCount + _shortAnswerCount;
  
  bool get _canGenerate => _selectedTotal == _totalQuestions && _selectedTotal > 0;

  void _generateQuiz() {
    if (!_canGenerate) {
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select exactly $_totalQuestions questions. Current: $_selectedTotal',
          ),
          backgroundColor: scheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Navigate to quiz generator with customization
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizGeneratorPage(
          documentId: widget.documentId,
          documentTitle: widget.documentTitle,
          extractedText: widget.extractedText,
          autoGenerate: true,
          totalQuestions: _totalQuestions,
          mcqCount: _mcqCount,
          trueFalseCount: _trueFalseCount,
          essayCount: _essayCount,
          shortAnswerCount: _shortAnswerCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Customize Quiz'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.blue50.withOpacity(0.4),
                    AppColors.cyanLight.withOpacity(0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SizedBox(height: 32),

            // Total questions selector
            Text(
              'Total Number of Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.cyan.withOpacity(0.05),
                    AppColors.accent.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _totalQuestions > 1
                              ? [AppColors.primary, AppColors.cyan]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _totalQuestions > 1
                            ? () {
                                setState(() {
                                  _totalQuestions--;
                                  _updateCounts();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove, color: Colors.white),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_totalQuestions',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _totalQuestions < 50
                              ? [AppColors.primary, AppColors.cyan]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _totalQuestions < 50
                            ? () {
                                setState(() {
                                  _totalQuestions++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add, color: Colors.white),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Question types
            Text(
              'Question Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _canGenerate
                      ? [AppColors.cyan.withOpacity(0.3), AppColors.primary.withOpacity(0.2)]
                      : [AppColors.orange.withOpacity(0.3), AppColors.amber.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _canGenerate
                      ? AppColors.cyan.withOpacity(0.5)
                      : AppColors.orange.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Text(
                'Selected: $_selectedTotal / $_totalQuestions',
                style: TextStyle(
                  fontSize: 14,
                  color: _canGenerate ? AppColors.cyan : AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // MCQ
            _buildQuestionTypeCard(
              icon: Icons.check_circle_outline,
              title: 'Multiple Choice',
              description: 'Choose the correct answer from options',
              count: _mcqCount,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onChanged: (value) {
                setState(() {
                  _mcqCount = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // True/False
            _buildQuestionTypeCard(
              icon: Icons.check_box_outlined,
              title: 'True or False',
              description: 'Determine if statements are true or false',
              count: _trueFalseCount,
              gradient: const LinearGradient(
                colors: [AppColors.cyan, AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onChanged: (value) {
                setState(() {
                  _trueFalseCount = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Short Answer
            _buildQuestionTypeCard(
              icon: Icons.short_text,
              title: 'Short Answer',
              description: 'Brief written responses',
              count: _shortAnswerCount,
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.indigo, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onChanged: (value) {
                setState(() {
                  _shortAnswerCount = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Essay
            _buildQuestionTypeCard(
              icon: Icons.article_outlined,
              title: 'Essay',
              description: 'Detailed written responses',
              count: _essayCount,
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onChanged: (value) {
                setState(() {
                  _essayCount = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Generate button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: _canGenerate
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.cyan, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _canGenerate
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(-2, -2),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: _canGenerate ? _generateQuiz : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _canGenerate ? Icons.auto_awesome : Icons.warning_amber,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _canGenerate
                          ? 'Generate Quiz'
                          : 'Select $_totalQuestions questions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
           
            
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildQuestionTypeCard({
    required IconData icon,
    required String title,
    required String description,
    required int count,
    required Gradient gradient,
    required Function(int) onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final maxAllowed = _totalQuestions - (_selectedTotal - count);
    final primaryColor = gradient.colors.first;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: count > 0 ? gradient : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: count > 0
                        ? () => onChanged(count - 1)
                        : null,
                    icon: const Icon(Icons.remove, color: Colors.white),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: count.toDouble().clamp(0.0, maxAllowed > 0 ? maxAllowed.toDouble() : 1.0),
                    min: 0,
                    max: maxAllowed > 0 ? maxAllowed.toDouble() : 1.0,
                    divisions: maxAllowed > 0 ? maxAllowed : 1,
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.3),
                    label: count.toString(),
                    onChanged: maxAllowed > 0 ? (value) => onChanged(value.toInt()) : null,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: count < maxAllowed ? gradient : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: count < maxAllowed
                        ? () => onChanged(count + 1)
                        : null,
                    icon: const Icon(Icons.add, color: Colors.white),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}