import 'package:flutter/material.dart';

class TrueFalseWidget extends StatefulWidget {
  final Function(String)? onAnswerChanged;
  final String? initialAnswer;

  const TrueFalseWidget({
    super.key,
    this.onAnswerChanged,
    this.initialAnswer,
  });

  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  String? answer;

  @override
  void initState() {
    super.initState();
    answer = widget.initialAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile(
          value: "True",
          groupValue: answer,
          onChanged: (v) {
            setState(() => answer = v);
            widget.onAnswerChanged?.call(v ?? '');
          },
          title: const Text("True"),
        ),
        RadioListTile(
          value: "False",
          groupValue: answer,
          onChanged: (v) {
            setState(() => answer = v);
            widget.onAnswerChanged?.call(v ?? '');
          },
          title: const Text("False"),
        ),
      ],
    );
  }
}
