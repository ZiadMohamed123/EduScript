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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select exactly $_totalQuestions questions. Current: $_selectedTotal',
          ),
          backgroundColor: Colors.orange,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Quiz'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SizedBox(height: 32),

            // Total questions selector
            const Text(
              'Total Number of Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _totalQuestions > 1
                          ? () {
                              setState(() {
                                _totalQuestions--;
                                _updateCounts();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_totalQuestions',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _totalQuestions < 50
                          ? () {
                              setState(() {
                                _totalQuestions++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Question types
            const Text(
              'Question Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: $_selectedTotal / $_totalQuestions',
              style: TextStyle(
                fontSize: 14,
                color: _canGenerate ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // MCQ
            _buildQuestionTypeCard(
              icon: Icons.check_circle_outline,
              title: 'Multiple Choice',
              description: 'Choose the correct answer from options',
              count: _mcqCount,
              color: Colors.blue,
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
              color: Colors.green,
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
              color: Colors.orange,
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
              color: Colors.purple,
              onChanged: (value) {
                setState(() {
                  _essayCount = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canGenerate ? _generateQuiz : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
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
    );
  }

  Widget _buildQuestionTypeCard({
    required IconData icon,
    required String title,
    required String description,
    required int count,
    required Color color,
    required Function(int) onChanged,
  }) {
    final maxAllowed = _totalQuestions - (_selectedTotal - count);
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                IconButton(
                  onPressed: count > 0
                      ? () => onChanged(count - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: color,
                ),
                Expanded(
                  child: Slider(
                    value: count.toDouble(),
                    min: 0,
                    max: maxAllowed.toDouble(),
                    divisions: maxAllowed > 0 ? maxAllowed : 1,
                    activeColor: color,
                    inactiveColor: color.withOpacity(0.3),
                    label: count.toString(),
                    onChanged: (value) => onChanged(value.toInt()),
                  ),
                ),
                IconButton(
                  onPressed: count < maxAllowed
                      ? () => onChanged(count + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: color,
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
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

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.accent.withOpacity(0.2),
      labelStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}