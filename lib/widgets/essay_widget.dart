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
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    
    return TextField(
      controller: _controller,
      maxLines: 6,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintText: "Write your answer...",
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
        filled: true,
        fillColor: scheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
      ),
    );
  }
}