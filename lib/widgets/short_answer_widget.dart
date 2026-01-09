import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/app_theme.dart';

class ShortAnswerWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswerChanged;

  const ShortAnswerWidget({
    super.key,
    required this.question,
    required this.onAnswerChanged,
  });

  @override
  State<ShortAnswerWidget> createState() => _ShortAnswerWidgetState();
}

class _ShortAnswerWidgetState extends State<ShortAnswerWidget> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.question.userAnswer ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character count indicator
        if (hasText)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.accent.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_controller.text.length} characters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Text field
        Focus(
          onFocusChange: (focused) {
            setState(() => _isFocused = focused);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: _isFocused || hasText
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.05),
                        AppColors.accent.withOpacity(0.05),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primary
                    : hasText
                        ? AppColors.accent.withOpacity(0.5)
                        : scheme.outline.withOpacity(0.3),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _controller,
              onChanged: widget.onAnswerChanged,
              maxLines: 3,
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.edit_note,
                    color: _isFocused
                        ? AppColors.primary
                        : scheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Helper text
        if (!hasText && !_isFocused)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Provide a concise answer',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}