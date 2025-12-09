import 'package:flutter/material.dart';

class ShortAnswerWidget extends StatelessWidget {
  const ShortAnswerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 1,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: "Your answer...",
      ),
    );
  }
}
