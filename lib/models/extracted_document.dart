import 'dart:convert';

class ExtractedDocument {
  final String documentId; // ✅ REQUIRED
  final String? title;
  final String? date;
  final String? studentName;
  final List<String> questions;
  final String rawText;

  ExtractedDocument({
    required this.documentId,
    this.title,
    this.date,
    this.studentName,
    required this.questions,
    required this.rawText,
  });

  factory ExtractedDocument.fromJson(Map<String, dynamic> json) {
    return ExtractedDocument(
      documentId: json['id'], // backend ID
      title: json['title'],
      date: json['date'],
      studentName: json['studentName'],
      questions: List<String>.from(json['questions'] ?? []),
      rawText: json['rawText'] ?? '',
    );
  }

  factory ExtractedDocument.fromRawText({
    required String rawText,
    required String documentId,
  }) {
    final lines = rawText.split('\n').map((e) => e.trim()).toList();

    return ExtractedDocument(
      documentId: documentId,
      title: lines.isNotEmpty ? lines.first : null,
      date: _extractDate(rawText),
      studentName: _extractStudent(rawText),
      questions: lines.where((e) => e.contains("?") || e.length > 20).toList(),
      rawText: rawText,
    );
  }

  static String? _extractDate(String text) {
    final regex = RegExp(r'\d{2}/\d{2}/\d{4}');
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  static String? _extractStudent(String text) {
    final regex = RegExp(r'(Name|Student|الاسم)\s*[:\- ]\s*(.+)');
    final match = regex.firstMatch(text);
    return match?.group(2);
  }
}
