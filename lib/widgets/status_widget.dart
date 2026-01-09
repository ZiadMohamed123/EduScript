import 'package:flutter/material.dart';

Widget statusWidget(String status) {
  IconData icon;
  Color color;

  if (status.contains('Scanning')) {
    icon = Icons.document_scanner;
    color = Colors.blue;
  } else if (status.contains('Creating')) {
    icon = Icons.picture_as_pdf;
    color = Colors.orange;
  } else if (status.contains('Done')) {
    icon = Icons.check_circle;
    color = Colors.green;
  } else if (status.contains('Failed') || status.contains('Error')) {
    icon = Icons.error;
    color = Colors.red;
  } else {
    icon = Icons.hourglass_empty;
    color = Colors.grey;
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
