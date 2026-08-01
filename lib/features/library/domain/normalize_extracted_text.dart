
import 'package:read_ru/features/library/domain/entities/document.dart';

/// Turns raw extracted text into clean paragraphs regardless of the source
/// format's quirks.
///
/// Output contract (what splitIntoWords expects):
///  - paragraphs separated by a blank line ('\n\n')
///  - no leading indentation, single spaces inside paragraphs
///  - each dialogue turn ("— Привет.") on its own paragraph
String normalizeExtractedText(String raw, DocumentFormat format) {
  final text = _cleanCharacters(raw);

  final paragraphs = switch (format) {
    // Syncfusion emits one \n per printed line: hard wraps mid-sentence,
    // words hyphenated across lines, no paragraph markers. Paragraphs have
    // to be reconstructed from line-shape heuristics.
    DocumentFormat.pdf => _reflowPrintedLines(text),

    // Plain text has no fixed convention - if the file uses blank lines
    // between paragraphs trust those, otherwise reflow like a PDF.
    DocumentFormat.txt => _hasBlankLines(text)
        ? _paragraphsFromBlankLines(text)
        : _reflowPrintedLines(text),

    // htmlToPlainText outputs blank lines between blocks, but HTML entities
    // like &nbsp; or &mdash; pass through it untouched - decode them first.
    DocumentFormat.epub ||
    DocumentFormat.mobi =>
      _paragraphsFromBlankLines(_decodeHtmlEntities(text)),

    // extractFb2Text joins <p> elements with blank lines - already
    // paragraph-true, only needs the shared tidying below.
    DocumentFormat.fb2 => _paragraphsFromBlankLines(text),
  };

  return paragraphs
      .expand(_splitInlineDialogue)
      .map(_tidyParagraph)
      .where((paragraph) => paragraph.isNotEmpty)
      .join('\n\n');
}

/// Sentence-final punctuation, optionally followed by a closing quote or
/// bracket: "конец.", "конец!»", 'конец?"'.
final _endsSentence = RegExp(r'[.!?…][»")]?$');

String _cleanCharacters(String text) {
  return text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\t', ' ')
      // Non-breaking and narrow spaces (NBSP, en/em spaces, narrow NBSP)
      // break word splitting - make them ordinary spaces.
      .replaceAll(RegExp(r'[\u00A0\u2000-\u200A\u202F]'), ' ')
      // Soft hyphens and zero-width characters are invisible but would end
      // up inside words - drop them entirely.
      .replaceAll(RegExp(r'[\u00AD\u200B-\u200D\uFEFF]'), '');
}

bool _hasBlankLines(String text) => RegExp(r'\n[ \t]*\n').hasMatch(text);

List<String> _paragraphsFromBlankLines(String text) {
  return text
      .split(RegExp(r'\n\s*\n'))
      .map(_unwrapLines)
      .where((paragraph) => paragraph.trim().isNotEmpty)
      .toList();
}

/// Joins the hard-wrapped lines inside one paragraph back into a single
/// line, gluing hyphenated words ("сло-\nво") back together.
String _unwrapLines(String paragraph) {
  final dehyphenated = paragraph.replaceAllMapped(
    RegExp(r'(\p{Ll})-\n[ \t]*(\p{Ll})', unicode: true),
    (m) => '${m[1]}${m[2]}',
  );
  return dehyphenated.replaceAll('\n', ' ');
}

/// Rebuilds paragraphs from print-shaped lines (PDF, wrapped TXT).
///
/// A new paragraph starts when a line is indented or opens with a dialogue
/// dash. A paragraph ends at a blank line, or when a line finishes a
/// sentence while stopping noticeably short of the page's full line width -
/// the classic shape of a paragraph's last line.
List<String> _reflowPrintedLines(String text) {
  final lines = text.split('\n');

  final lengths = lines
      .map((line) => line.trim().length)
      .where((length) => length > 0)
      .toList()
    ..sort();
  if (lengths.isEmpty) return const [];

  // The median tells us how wide a "full" printed line is, so short last
  // lines stand out. Very long medians mean the source already emits whole
  // paragraphs per line - nothing to reflow.
  final median = lengths[lengths.length ~/ 2];
  if (median > 120) {
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  final paragraphs = <String>[];
  final current = StringBuffer();

  void flush() {
    final paragraph = current.toString().trim();
    if (paragraph.isNotEmpty) paragraphs.add(paragraph);
    current.clear();
  }

  for (final rawLine in lines) {
    final trimmed = rawLine.trim();

    if (trimmed.isEmpty) {
      flush();
      continue;
    }

    final indented = rawLine.length - rawLine.trimLeft().length >= 2;
    if (indented || _startsWithDialogueDash(trimmed)) {
      flush();
    }

    if (current.isEmpty) {
      current.write(trimmed);
    } else {
      final soFar = current.toString();
      // A trailing hyphen before a lowercase continuation is a word split
      // at the line end - rejoin it without the hyphen.
      if (soFar.endsWith('-') && _startsLowercase(trimmed)) {
        current.clear();
        current.write(soFar.substring(0, soFar.length - 1));
        current.write(trimmed);
      } else {
        current.write(' ');
        current.write(trimmed);
      }
    }

    final short = trimmed.length < median * 0.8;
    if (short && _endsSentence.hasMatch(trimmed)) {
      flush();
    }
  }

  flush();
  return paragraphs;
}

bool _startsWithDialogueDash(String line) =>
    RegExp(r'^[—–-]\s').hasMatch(line);

bool _startsLowercase(String text) =>
    RegExp(r'^\p{Ll}', unicode: true).hasMatch(text);

/// Splits dialogue turns that got glued onto one line: in "— Да. — Нет!" the
/// dash right after a finished sentence opens a new speaker's turn. A dash
/// after a comma ("— Привет, — сказал он") is attribution and stays inline.
List<String> _splitInlineDialogue(String paragraph) {
  return paragraph.split(
    RegExp(r'(?<=[.!?…][»")]?)\s+(?=[—–]\s)'),
  );
}

String _tidyParagraph(String paragraph) {
  return paragraph
      // PDF extraction likes leaving stray spaces before punctuation.
      .replaceAllMapped(RegExp(r' +([.,!?;:…])'), (m) => m[1]!)
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
}

String _decodeHtmlEntities(String text) {
  const named = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&#39;': "'",
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
    '&laquo;': '«',
    '&raquo;': '»',
  };

  var result = text;
  named.forEach((entity, char) {
    result = result.replaceAll(entity, char);
  });

  // Numeric entities: &#1071; (decimal) or &#x42F; (hex).
  return result.replaceAllMapped(RegExp(r'&#([xX]?)([0-9a-fA-F]+);'), (m) {
    final isHex = m[1]!.isNotEmpty;
    final code = int.tryParse(m[2]!, radix: isHex ? 16 : 10);
    return code == null ? m[0]! : String.fromCharCode(code);
  });
}
