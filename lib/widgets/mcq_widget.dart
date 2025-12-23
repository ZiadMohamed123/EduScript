import 'package:flutter/material.dart';

class McqWidget extends StatefulWidget {
  final List<String> options;
  final Function(String)? onAnswerChanged;
  final String? initialAnswer;

  const McqWidget({
    super.key,
    required this.options,
    this.onAnswerChanged,
    this.initialAnswer,
  });

  @override
  State<McqWidget> createState() => _McqWidgetState();
}

class _McqWidgetState extends State<McqWidget> {
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialAnswer;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Column(
      children: widget.options.map((opt) {
        return RadioListTile<String>(
          value: opt,
          groupValue: selected,
          onChanged: (value) {
            setState(() => selected = value);
            widget.onAnswerChanged?.call(value ?? '');
          },
          title: Text(
            opt,
            style: TextStyle(color: scheme.onSurface),
          ),
          activeColor: scheme.primary,
        );
      }).toList(),
    );
  }
}