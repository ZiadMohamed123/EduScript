import 'question_type.dart';

class Question {
  final int id;
  final QuestionType type;
  final String text;
  final List<String> options;
  final String? answer;

  Question({
    required this.id,
    required this.type,
    required this.text,
    this.options = const [],
    this.answer,
  });
}
