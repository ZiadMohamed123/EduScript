import 'package:flutter/material.dart';

class TrueFalseWidget extends StatefulWidget {
  const TrueFalseWidget({super.key});

  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  String? answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile(
          value: "True",
          groupValue: answer,
          onChanged: (v) => setState(() => answer = v),
          title: const Text("True"),
        ),
        RadioListTile(
          value: "False",
          groupValue: answer,
          onChanged: (v) => setState(() => answer = v),
          title: const Text("False"),
        ),
      ],
    );
  }
}
