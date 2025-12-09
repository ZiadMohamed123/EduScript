import 'package:flutter/material.dart';
import '../models/question.dart';

class QuizProvider extends ChangeNotifier {
  List<Question> questions = [];
  int currentIndex = 0;

  void setQuestions(List<Question> list) {
    questions = list;
    currentIndex = 0;
    notifyListeners();
  }

  void next() {
    if (currentIndex < questions.length - 1) {
      currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  void reset() {
    questions = [];
    currentIndex = 0;
    notifyListeners();
  }
}
