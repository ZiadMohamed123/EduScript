import 'package:flutter/material.dart';

class EssayWidget extends StatelessWidget {
  const EssayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 6,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: "Write your answer...",
      ),
    );
  }
}
