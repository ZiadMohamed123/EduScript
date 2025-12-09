import 'package:flutter/material.dart';
import 'screens/quiz_generator_page.dart';

void main() {
  runApp(const QuizGeneratorApp());
}

class QuizGeneratorApp extends StatelessWidget {
  const QuizGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Quiz Generator",
      debugShowCheckedModeBanner: false,
      home: const QuizGeneratorPage(),
    );
  }
}
