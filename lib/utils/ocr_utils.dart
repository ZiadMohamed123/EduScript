class OCRUtils {
  static String clean(String text) {
    return text
        .replaceAll("\n\n", "\n")
        .replaceAll("\t", " ")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
