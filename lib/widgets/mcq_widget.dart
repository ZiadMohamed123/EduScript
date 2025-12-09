import 'package:flutter/material.dart';

class McqWidget extends StatefulWidget {
  final List<String> options;
  

  const McqWidget({super.key, required this.options});

  @override
  State<McqWidget> createState() => _McqWidgetState();
}

class _McqWidgetState extends State<McqWidget> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      
      children: widget.options.map((opt) {
        return RadioListTile<String>(
          value: opt,
          groupValue: selected,
          onChanged: (value) {
            setState(() => selected = value);
          },
          title: Text(opt),
        );
      }).toList(),
    );
  }
}
