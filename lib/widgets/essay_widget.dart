import 'package:flutter/material.dart';

class EssayWidget extends StatefulWidget {
  final Function(String)? onAnswerChanged;
  final String? initialAnswer;

  const EssayWidget({
    super.key,
    this.onAnswerChanged,
    this.initialAnswer,
  });

  @override
  State<EssayWidget> createState() => _EssayWidgetState();
}

class _EssayWidgetState extends State<EssayWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAnswer ?? '');
    _controller.addListener(() {
      widget.onAnswerChanged?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 6,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: "Write your answer...",
      ),
    );
  }
}
