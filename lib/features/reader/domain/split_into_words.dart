// Marker inserted between paragraphs so downstream pagination/rendering can
// force a line break there. A real word can never equal this, since it's
// produced only at blank-line boundaries, never by the word-splitting regex.
const paragraphBreak = '\n';

List<String> splitIntoWords(String text) {
  final paragraphs = text.split(RegExp(r'\n\s*\n'));
  final words = <String>[];

  for (var i = 0; i < paragraphs.length; i++) {
    words.addAll(
      paragraphs[i].split(RegExp(r'\s+')).where((word) => word.isNotEmpty),
    );
    if (i < paragraphs.length - 1) {
      words.add(paragraphBreak);
    }
  }

  return words;
}
