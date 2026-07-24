
import 'package:flutter/painting.dart' show TextScaler;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'reader_state.dart';
import 'package:read_ru/features/reader/domain/split_into_words.dart';
import 'package:read_ru/features/reader/presentation/layout/measured_pagination.dart';


class ReaderCubit extends Cubit<ReaderState>{
  ReaderCubit({this.onProgressChanged}) : super(ReaderInitial());

  final Future<void> Function(int lastWordIndex, double progress, Set<int> tappedWordIndices)? onProgressChanged;

  late List<String> _words;
  late double _containerWidth;
  late double _containerHeight;
  late TextScaler _textScaler;

  List<List<String>> _paginate(double fontSize) {
    final measurer = WordMeasurer(fontSize: fontSize, textScaler: _textScaler);
    return paginateMeasured(
      words: _words,
      measurer: measurer,
      containerWidth: _containerWidth,
      containerHeight: _containerHeight,
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

  Future<void> _reportProgress(List<List<String>> pages, int pageIndex, Set<int> tappedWordIndices) {
    if (onProgressChanged == null || _words.isEmpty) return Future.value();
    final wordIndex = _startIndexOfPage(pages, pageIndex);
    return onProgressChanged!(wordIndex, wordIndex / _words.length, tappedWordIndices);
  }

  // Explicit, awaitable save of wherever the reader currently is. Call this
  // (and await it) right before leaving the screen - do not rely on close()
  // timing relative to navigation, since widget disposal can happen after
  // the pop's own Future has already resolved.
  Future<void> saveProgress() {
    final current = state;
    if (current is! ReaderLoaded) return Future.value();
    return _reportProgress(current.pages, current.currentPageIndex, current.tappedWordIndices);
  }

  void loadDocument(
      String text, {
        required double containerWidth,
        required double containerHeight,
        double fontSize = 16,
        TextScaler textScaler = TextScaler.noScaling,
        int initialWordIndex = 0,
        Set<int> initialTappedWordIndices = const {},
      }) {
    emit(ReaderLoading());

    try {
      _words = splitIntoWords(text);
      _containerWidth = containerWidth;
      _containerHeight = containerHeight;
      _textScaler = textScaler;

      final pages = _paginate(fontSize);
      final startPage = _pageContainingWordIndex(pages, initialWordIndex);

      emit(ReaderLoaded(
        pages: pages,
        currentPageIndex: startPage,
        fontSize: fontSize,
        tappedWordIndices: initialTappedWordIndices,
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
    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: newPageIndex,
      fontSize: current.fontSize,
      tappedWordIndices: current.tappedWordIndices,
    ));
    _reportProgress(current.pages, newPageIndex, current.tappedWordIndices);
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
      tappedWordIndices: current.tappedWordIndices,
    ));
    _reportProgress(current.pages, newPageIndex, current.tappedWordIndices);
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

    emit(ReaderLoaded(
      pages: current.pages,
      currentPageIndex: current.currentPageIndex,
      fontSize: current.fontSize,
      tappedWordIndices: updatedIndices,
    ));
  }

  void changeFontSize(double newFontSize) {
    final current = state;
    if (current is! ReaderLoaded) return;

    final pages = _paginate(newFontSize);

    emit(ReaderLoaded(
      pages: pages,
      currentPageIndex: 0,
      fontSize: newFontSize,
      tappedWordIndices: current.tappedWordIndices,
    ));
  }

}
