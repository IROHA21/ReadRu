String htmlToPlainText(String html) {
  final collapsedWhitespace = html.replaceAll(RegExp(r'\s+'), ' ');
  final withBreaks = collapsedWhitespace.replaceAll(
    RegExp(r'</(p|div|br|h[1-6]|li)>', caseSensitive: false),
    '\n',
  );
  final stripped = withBreaks.replaceAll(RegExp(r'<[^>]*>'), '');
  return stripped.trim();
}