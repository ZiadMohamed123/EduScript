import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/app_theme.dart';

class TrueFalseWidget extends StatelessWidget {
  final Question question;
  final Function(String) onAnswerSelected;

  const TrueFalseWidget({
    super.key,
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = ['True', 'False'];

    return Row(
      children: options.map((option) {
        final isSelected = question.userAnswer == option;
        final isTrue = option == 'True';

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isTrue ? 6 : 0,
              left: isTrue ? 0 : 6,
            ),
            child: InkWell(
              onTap: () => onAnswerSelected(option),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.accent.withOpacity(0.15),
                          ],
                        )
                      : null,
                  color: isSelected ? null : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : scheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : scheme.outline.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isTrue ? Icons.check_circle : Icons.cancel,
                        size: 32,
                        color: isSelected
                            ? Colors.white
                            : (isTrue ? Colors.green : Colors.red)
                                .withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Text
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),

                    // Selected indicator
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}