class ExtractedDocument {
  final String? title;
  final String? date;
  final String? studentName;
  final List<String> questions;

  ExtractedDocument({
    this.title,
    this.date,
    this.studentName,
    required this.questions,
  });

  factory ExtractedDocument.fromRawText(String raw) {
    final lines = raw.split("\n").map((e) => e.trim()).toList();

    return ExtractedDocument(
      title: lines.isNotEmpty ? lines.first : null,
      date: _extractDate(raw),
      studentName: _extractStudent(raw),
      questions: lines.where((e) => e.contains("?") || e.length > 20).toList(),
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
