import 'package:flutter/painting.dart' show TextScaler;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'reader_state.dart';
import 'package:read_ru/features/library/domain/entities/chapter.dart';
import 'package:read_ru/features/reader/domain/split_into_words.dart';
import 'package:read_ru/features/reader/presentation/layout/measured_pagination.dart';
import 'package:read_ru/features/settings/domain/reader_font.dart';


class ReaderCubit extends Cubit<ReaderState>{
  ReaderCubit({this.onProgressChanged}) : super(ReaderInitial());

  final Future<void> Function(
    int lastWordIndex,
    double progress,
    Set<int> tappedWordIndices,
    Map<int, String> translatedWords,
  )? onProgressChanged;

  late List<String> _words;
  late double _containerWidth;
  late double _containerHeight;
  late TextScaler _textScaler;
  late ReaderFont _font;
  late double _translationFontSize;
  Set<int> _chapterBreaks = const {};

  List<List<String>> _paginate(double fontSize) {
    final measurer = WordMeasurer(
      fontSize: fontSize,
      font: _font,
      translationFontSize: _translationFontSize,
      textScaler: _textScaler,
    );
    return paginateMeasured(
      words: _words,
      measurer: measurer,
      containerWidth: _containerWidth,
      containerHeight: _containerHeight,
      chapterBreaks: _chapterBreaks,
    );
  }

  // Index of the first word on [pageIndex], counting all words on earlier pages.
  int _startIndexOfPage(List<List<String>> pages, int pageIndex) {
    var index = 0;
    for (var i = 0; i < pageIndex; i++) {
      index += pages[i].length;
    }
    return index;
  }

  // Which page (in a freshly-paginated list) contains a given word index -
  // used to resume at the right page after re-pagination, since page numbers
  // themselves are not stable across font size / container changes.
  int _pageContainingWordIndex(List<List<String>> pages, int wordIndex) {
    var cumulative = 0;
    for (var i = 0; i < pages.length; i++) {
      cumulative += pages[i].length;
      if (wordIndex < cumulative) return i;
    }
    return pages.isEmpty ? 0 : pages.length - 1;
  }

  Future<void> _reportProgress(
    List<List<String>> pages,
    int pageIndex,
    Set<int> tappedWordIndices,
    Map<int, String> translatedWords,
  ) {
    if (onProgressChanged == null || _words.isEmpty) return Future.value();
    final wordIndex = _startIndexOfPage(pages, pageIndex);
    return onProgressChanged!(wordIndex, wordIndex / _words.length, tappedWordIndices, translatedWords);
  }

  // Explicit, awaitable save of wherever the reader currently is. Call this
  // (and await it) right before leaving the screen - do not rely on close()
  // timing relative to navigation, since widget disposal can happen after
  // the pop's own Future has already resolved.
  Future<void> saveProgress() {
    final current = state;
    if (current is! ReaderLoaded) return Future.value();
    return _reportProgress(current.pages, current.currentPageIndex, current.tappedWordIndices, current.translatedWords);
  }

  void loadDocument(
      String text, {
        required double containerWidth,
        required double containerHeight,
        required ReaderFont font,
        required double translationFontSize,
        double fontSize = 16,
        TextScaler textScaler = TextScaler.noScaling,
        int initialWordIndex = 0,
        Set<int> initialTappedWordIndices = const {},
        Map<int, String> initialTranslatedWords = const {},
        List<Chapter> chapters = const [],
      }) {
    emit(ReaderLoading());

    try {
      _words = splitIntoWords(text);
      _containerWidth = containerWidth;
      _containerHeight = containerHeight;
      _textScaler = textScaler;
      _font = font;
      _translationFontSize = translationFontSize;
      _chapterBreaks = chapters.map((c) => c.wordIndex).toSet();

      final pages = _paginate(fontSize);
      final startPage = _pageContainingWordIndex(pages, initialWordIndex);

      emit(ReaderLoaded(
        pages: pages,
        currentPageIndex: startPage,
        fontSize: fontSize,
        font: _font,
        translationFontSize: _translationFontSize,
        tappedWordIndices: initialTappedWordIndices,
        translatedWords: initialTranslatedWords,
      ));
    } catch (e) {
      emit(ReaderError(e.toString()));
      emit(ReaderInitial());
    }

  }

  void nextPage() {
    final current = state;
    if (current is! ReaderLoaded) return;
    if (current.currentPageIndex >= current.pages.length - 1) return;

    final newPageIndex = current.currentPageIndex + 1;
    // Page navigation always clears an in-progress phrase selection - the
    // selected words are about to scroll off screen anyway.
    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: newPageIndex,
      fontSize: current.fontSize,
      font: current.font,
      translationFontSize: current.translationFontSize,
      tappedWordIndices: current.tappedWordIndices,
      translatedWords: current.translatedWords,
    ));
    _reportProgress(current.pages, newPageIndex, current.tappedWordIndices, current.translatedWords);
  }

  void previousPage() {
    final current = state;
    if (current is! ReaderLoaded) return;
    if (current.currentPageIndex <= 0) return;

    final newPageIndex = current.currentPageIndex - 1;
    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: newPageIndex,
      fontSize: current.fontSize,
      font: current.font,
      translationFontSize: current.translationFontSize,
      tappedWordIndices: current.tappedWordIndices,
      translatedWords: current.translatedWords,
    ));
    _reportProgress(current.pages, newPageIndex, current.tappedWordIndices, current.translatedWords);
  }

  // Jumps to a chapter's word index (see Chapter.wordIndex - approximate
  // for formats that reflow text, but close). Clears any in-progress
  // selection, same as regular page navigation.
  void jumpToWordIndex(int wordIndex) {
    final current = state;
    if (current is! ReaderLoaded || _words.isEmpty) return;

    final clamped = wordIndex.clamp(0, _words.length - 1);
    final newPageIndex = _pageContainingWordIndex(current.pages, clamped);

    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: newPageIndex,
      fontSize: current.fontSize,
      font: current.font,
      translationFontSize: current.translationFontSize,
      tappedWordIndices: current.tappedWordIndices,
      translatedWords: current.translatedWords,
    ));
    _reportProgress(current.pages, newPageIndex, current.tappedWordIndices, current.translatedWords);
  }

  void toggleWord(int wordIndex) {
    final current = state;
    if (current is! ReaderLoaded) return;

    final updatedIndices = Set<int>.from(current.tappedWordIndices);
    if (updatedIndices.contains(wordIndex)) {
      updatedIndices.remove(wordIndex);
    } else {
      updatedIndices.add(wordIndex);
    }

    emit(current.copyWith(tappedWordIndices: updatedIndices));
  }

  // Caches a word's translation next to its index so re-opening the book
  // (or just re-tapping it) never needs to hit the translation API again.
  void setTranslation(int wordIndex, String translation) {
    final current = state;
    if (current is! ReaderLoaded) return;
    if (translation.isEmpty || translation == '(failed)') return;

    final updated = Map<int, String>.from(current.translatedWords);
    updated[wordIndex] = translation;

    emit(current.copyWith(translatedWords: updated));
  }

  // Called when the Settings screen changes something that affects layout
  // (font size, font family, translation text size) while a book is already
  // open - re-paginates and lands back on the same word the reader was at,
  // rather than resetting to page 0.
  void applySettings({
    required double fontSize,
    required ReaderFont font,
    required double translationFontSize,
  }) {
    final current = state;
    if (current is! ReaderLoaded) return;

    final currentWordIndex = _startIndexOfPage(current.pages, current.currentPageIndex);
    _font = font;
    _translationFontSize = translationFontSize;

    final pages = _paginate(fontSize);
    final newPageIndex = _pageContainingWordIndex(pages, currentWordIndex);

    emit(current.copyWith(
      pages: pages,
      currentPageIndex: newPageIndex,
      fontSize: fontSize,
      font: font,
      translationFontSize: translationFontSize,
    ));
  }

  // --- Phrase selection ---
  // A long-press starts it (anchor = focus = that word); tapping any other
  // word while selecting moves the focus end, extending/shrinking the range
  // toward it. Selection is restricted in practice to one page at a time -
  // page navigation clears it (see nextPage/previousPage).

  void startSelection(int wordIndex) {
    final current = state;
    if (current is! ReaderLoaded) return;
    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: current.currentPageIndex,
      fontSize: current.fontSize,
      font: current.font,
      translationFontSize: current.translationFontSize,
      tappedWordIndices: current.tappedWordIndices,
      translatedWords: current.translatedWords,
      selectionAnchor: wordIndex,
      selectionFocus: wordIndex,
    ));
  }

  void extendSelection(int wordIndex) {
    final current = state;
    if (current is! ReaderLoaded || current.selectionAnchor == null) return;
    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: current.currentPageIndex,
      fontSize: current.fontSize,
      font: current.font,
      translationFontSize: current.translationFontSize,
      tappedWordIndices: current.tappedWordIndices,
      translatedWords: current.translatedWords,
      selectionAnchor: current.selectionAnchor,
      selectionFocus: wordIndex,
    ));
  }

  void clearSelection() {
    final current = state;
    if (current is! ReaderLoaded) return;
    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: current.currentPageIndex,
      fontSize: current.fontSize,
      font: current.font,
      translationFontSize: current.translationFontSize,
      tappedWordIndices: current.tappedWordIndices,
      translatedWords: current.translatedWords,
      selectionAnchor: null,
      selectionFocus: null,
    ));
  }

  // The selected phrase's plain text, words in document order regardless of
  // which end the user dragged from - or null if nothing is selected.
  String? selectedPhraseText() {
    final current = state;
    if (current is! ReaderLoaded) return null;
    final anchor = current.selectionAnchor;
    final focus = current.selectionFocus;
    if (anchor == null || focus == null) return null;

    final start = anchor < focus ? anchor : focus;
    final end = (anchor < focus ? focus : anchor).clamp(0, _words.length - 1);
    final phrase = _words
        .sublist(start, end + 1)
        .where((w) => w != paragraphBreak)
        .join(' ')
        .trim();
    return phrase.isEmpty ? null : phrase;
  }

  int get selectedWordCount {
    final current = state;
    if (current is! ReaderLoaded) return 0;
    final anchor = current.selectionAnchor;
    final focus = current.selectionFocus;
    if (anchor == null || focus == null) return 0;
    final start = anchor < focus ? anchor : focus;
    final end = anchor < focus ? focus : anchor;
    return _words.sublist(start, end + 1).where((w) => w != paragraphBreak).length;
  }
}
