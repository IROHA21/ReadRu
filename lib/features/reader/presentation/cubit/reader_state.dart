import 'package:read_ru/features/settings/domain/reader_font.dart';

// Sentinel translation results that should never be cached (per-word in
// Document.translatedWords, or in reader_view.dart's in-memory cache) or
// saved to the word bucket - they're not real translations, just reasons
// one didn't happen.
const String translationFailedMarker = '(failed)';
const String translationUnsupportedMarker = '(language not supported)';

bool isUsableTranslation(String translation) =>
    translation.isNotEmpty &&
    translation != translationFailedMarker &&
    translation != translationUnsupportedMarker;

sealed class ReaderState {}

class ReaderInitial extends ReaderState {}

class ReaderLoading extends ReaderState {}

class ReaderLoaded extends ReaderState {
  final List<List<String>> pages;
  final int currentPageIndex;
  final double fontSize;
  final ReaderFont font;
  final double translationFontSize;
  final Set<int> tappedWordIndices;
  // Word index -> translation, persisted so re-opening a book doesn't
  // re-hit the translation API for words already translated before.
  final Map<int, String> translatedWords;
  // Phrase-selection mode: both null when not selecting. Anchor is the word
  // a long-press started on; focus is the last word tapped to extend the
  // range - whichever of the two is smaller/larger doesn't matter, the
  // selected range is always [min, max].
  final int? selectionAnchor;
  final int? selectionFocus;

  ReaderLoaded({
    required this.pages,
    required this.currentPageIndex,
    required this.fontSize,
    required this.font,
    required this.translationFontSize,
    required this.tappedWordIndices,
    required this.translatedWords,
    this.selectionAnchor,
    this.selectionFocus,
  });

  bool get isSelecting => selectionAnchor != null;

  // Doesn't touch selectionAnchor/selectionFocus - callers that need to
  // change or clear the selection construct ReaderLoaded directly instead,
  // since copyWith has no clean way to distinguish "leave as-is" from
  // "set to null".
  ReaderLoaded copyWith({
    List<List<String>>? pages,
    int? currentPageIndex,
    double? fontSize,
    ReaderFont? font,
    double? translationFontSize,
    Set<int>? tappedWordIndices,
    Map<int, String>? translatedWords,
  }) {
    return ReaderLoaded(
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      fontSize: fontSize ?? this.fontSize,
      font: font ?? this.font,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      tappedWordIndices: tappedWordIndices ?? this.tappedWordIndices,
      translatedWords: translatedWords ?? this.translatedWords,
      selectionAnchor: selectionAnchor,
      selectionFocus: selectionFocus,
    );
  }
}

class ReaderError extends ReaderState {
  final String message;
  ReaderError(this.message);
}
