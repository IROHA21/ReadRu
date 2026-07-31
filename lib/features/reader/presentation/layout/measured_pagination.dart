import 'package:flutter/painting.dart';
import 'package:read_ru/features/reader/domain/split_into_words.dart';
import 'package:read_ru/features/settings/domain/reader_font.dart';

/// Text metrics pinned explicitly so the measurer and _WordWidget render with
/// identical styles. Without this, Text widgets inherit the Material theme's
/// line-height/letter-spacing and end up taller than what TextPainter measured.
const double readerLineHeight = 1.2;
const double readerLetterSpacing = 0;

/// Gaps used by both the Wrap in reader_view.dart and the paginator below -
/// shared constants so the two can never disagree.
const double readerWordSpacing = 8;
const double readerRunSpacing = 4;

TextStyle readerTextStyle(double fontSize, {required ReaderFont font, Color? color}) =>
    font.apply(TextStyle(
      fontSize: fontSize,
      height: readerLineHeight,
      letterSpacing: readerLetterSpacing,
      color: color,
    ));

/// Measures real rendered text sizes with TextPainter instead of estimating
/// them from typographic constants. Char widths are cached, so repeated
/// letters cost one layout pass each.
class WordMeasurer {
  WordMeasurer({
    required this.fontSize,
    required this.font,
    required this.translationFontSize,
    required this.textScaler,
  });

  final double fontSize;
  final ReaderFont font;
  final double translationFontSize;
  final TextScaler textScaler;
  final Map<String, double> _charWidths = {};

  double _charWidth(String char) {
    return _charWidths.putIfAbsent(char, () {
      final painter = TextPainter(
        text: TextSpan(text: char, style: readerTextStyle(fontSize, font: font)),
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
  /// translation line under it - translationFontSize must match what
  /// _WordWidget actually renders, whatever the user set it to.
  double rowHeight() {
    final wordPainter = TextPainter(
      text: TextSpan(text: 'Йy', style: readerTextStyle(fontSize, font: font)),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final translationPainter = TextPainter(
      text: TextSpan(text: 'Йy', style: readerTextStyle(translationFontSize, font: font)),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final height = wordPainter.height + translationPainter.height;
    wordPainter.dispose();
    translationPainter.dispose();
    return height;
  }
}

/// TextPainter's measured row height runs very slightly under what the same
/// text actually occupies once rendered through a real Wrap/Text - close
/// enough that most pages have slack to absorb it, but a page whose last row
/// lands right at the containerHeight boundary can fit one row more than
/// actually renders, clipping (or visually overlapping the fixed bottom bar
/// with) that row. Keeping the last row's bottom this far clear of the
/// boundary is enough slack to absorb that drift without losing a
/// perceptible amount of page content.
const double _pageHeightSafetyMargin = 12;

/// Simulates the reader's Wrap layout word by word with measured widths,
/// cutting a new page when the next row would not fit the container height.
/// [chapterBreaks] are word indices a chapter starts at (see Chapter.wordIndex) -
/// a page is force-cut right before any of them, so a chapter never has to
/// share a page with the tail end of the previous one.
List<List<String>> paginateMeasured({
  required List<String> words,
  required WordMeasurer measurer,
  required double containerWidth,
  required double containerHeight,
  double wordSpacing = readerWordSpacing,
  double runSpacing = readerRunSpacing,
  Set<int> chapterBreaks = const {},
}) {
  final pages = <List<String>>[];
  var page = <String>[];

  final usableHeight = containerHeight - _pageHeightSafetyMargin;
  final rowHeight = measurer.rowHeight();
  var lineX = 0.0;
  var usedHeight = rowHeight;

  for (var i = 0; i < words.length; i++) {
    final word = words[i];

    if (chapterBreaks.contains(i) && page.isNotEmpty) {
      pages.add(page);
      page = <String>[];
      usedHeight = rowHeight;
      lineX = 0;
    }

    if (word == paragraphBreak) {
      // Forces the next word onto a new row, same page-break logic as an
      // ordinary wrap - just triggered explicitly instead of by width.
      final heightWithNewRow = usedHeight + runSpacing + rowHeight;
      if (heightWithNewRow <= usableHeight) {
        usedHeight = heightWithNewRow;
      } else {
        pages.add(page);
        page = <String>[];
        usedHeight = rowHeight;
      }
      lineX = 0;
      page.add(word);
      continue;
    }

    final width = measurer.wordWidth(word);

    final neededX = lineX == 0 ? width : lineX + wordSpacing + width;
    if (neededX <= containerWidth) {
      lineX = neededX;
    } else {
      final heightWithNewRow = usedHeight + runSpacing + rowHeight;
      if (heightWithNewRow <= usableHeight) {
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
