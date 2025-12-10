import 'dart:async';
import '../models/question.dart';
import '../models/question_type.dart';

class QuizApiService {
  Future<List<Question>> generateQuiz(String notes) async {
    // TODO: Replace with real API call
    await Future.delayed(const Duration(seconds: 2));

    return [
      Question(
        id: 1,
        type: QuestionType.mcq,
        text: "What is the main idea of the notes?",
        options: ["A", "B", "C", "D"],
      ),
      Question(
        id: 2,
        type: QuestionType.trueFalse,
        text: "The author argued about the main topic.",
        options: ["True", "False"],
      ),
      Question(
        id: 3,
        type: QuestionType.essay,
        text: "Explain the core concept discussed in the notes.",
      ),
      Question(
        id: 4,
        type: QuestionType.shortAnswer,
        text: "Define the main term used.",
      ),
    ];
  }
}
