

sealed class ReaderState {}

class ReaderInitial extends ReaderState {}

class ReaderLoading extends ReaderState {}

class ReaderLoaded extends ReaderState {
  final List<List<String>> pages;
  final int currentPageIndex;
  final double fontSize;
  final Set<int> tappedWordIndices;
  ReaderLoaded({
    required this.pages,
    required this.currentPageIndex,
    required this.fontSize,
    required this.tappedWordIndices,
  });
}

class ReaderError extends ReaderState {
  final String message;
  ReaderError(this.message);
}