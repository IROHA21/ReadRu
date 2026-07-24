import 'package:flutter/painting.dart';

/// Text metrics pinned explicitly so the measurer and _WordWidget render with
/// identical styles. Without this, Text widgets inherit the Material theme's
/// line-height/letter-spacing and end up taller than what TextPainter measured.
const double readerLineHeight = 1.2;
const double readerLetterSpacing = 0;

/// Gaps used by both the Wrap in reader_view.dart and the paginator below -
/// shared constants so the two can never disagree.
const double readerWordSpacing = 8;
const double readerRunSpacing = 4;

TextStyle readerTextStyle(double fontSize, {Color? color}) => TextStyle(
      fontSize: fontSize,
      height: readerLineHeight,
      letterSpacing: readerLetterSpacing,
      color: color,
    );

/// Measures real rendered text sizes with TextPainter instead of estimating
/// them from typographic constants. Char widths are cached, so repeated
/// letters cost one layout pass each.
class WordMeasurer {
  WordMeasurer({
    required this.fontSize,
    required this.textScaler,
  });

  final double fontSize;
  final TextScaler textScaler;
  final Map<String, double> _charWidths = {};

  double _charWidth(String char) {
    return _charWidths.putIfAbsent(char, () {
      final painter = TextPainter(
        text: TextSpan(text: char, style: readerTextStyle(fontSize)),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    });
  }

  /// Sum of per-char widths. Ignores kerning between letters, which is a
  /// tiny error the page's ClipRect absorbs.
  double wordWidth(String word) {
    var width = 0.0;
    for (final char in word.split('')) {
      width += _charWidth(char);
    }
    return width;
  }

  /// Real height of one word row: the word line plus the always-reserved
  /// translation line under it (0.7 ratio must match _WordWidget).
  double rowHeight() {
    final wordPainter = TextPainter(
      text: TextSpan(text: 'Йy', style: readerTextStyle(fontSize)),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final translationPainter = TextPainter(
      text: TextSpan(text: 'Йy', style: readerTextStyle(fontSize * 0.7)),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final height = wordPainter.height + translationPainter.height;
    wordPainter.dispose();
    translationPainter.dispose();
    return height;
  }
}

/// Simulates the reader's Wrap layout word by word with measured widths,
/// cutting a new page when the next row would not fit the container height.
List<List<String>> paginateMeasured({
  required List<String> words,
  required WordMeasurer measurer,
  required double containerWidth,
  required double containerHeight,
  double wordSpacing = readerWordSpacing,
  double runSpacing = readerRunSpacing,
}) {
  final pages = <List<String>>[];
  var page = <String>[];

  final rowHeight = measurer.rowHeight();
  var lineX = 0.0;
  var usedHeight = rowHeight;

  for (final word in words) {
    final width = measurer.wordWidth(word);

    final neededX = lineX == 0 ? width : lineX + wordSpacing + width;
    if (neededX <= containerWidth) {
      lineX = neededX;
    } else {
      final heightWithNewRow = usedHeight + runSpacing + rowHeight;
      if (heightWithNewRow <= containerHeight) {
        usedHeight = heightWithNewRow;
      } else {
        pages.add(page);
        page = <String>[];
        usedHeight = rowHeight;
      }
      lineX = width;
    }
    page.add(word);
  }

  if (page.isNotEmpty) {
    pages.add(page);
  }
  if (pages.isEmpty) {
    pages.add([]);
  }
  return pages;
}
