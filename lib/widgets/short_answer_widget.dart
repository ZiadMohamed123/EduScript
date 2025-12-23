import 'package:flutter/material.dart';

class ShortAnswerWidget extends StatefulWidget {
  final Function(String)? onAnswerChanged;
  final String? initialAnswer;

  const ShortAnswerWidget({
    super.key,
    this.onAnswerChanged,
    this.initialAnswer,
  });

  @override
  State<ShortAnswerWidget> createState() => _ShortAnswerWidgetState();
}

class _ShortAnswerWidgetState extends State<ShortAnswerWidget> {
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
      maxLines: 1,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: "Your answer...",
      ),
    );
  }
}
