// A chapter/section heading found in the book's own structure (EPUB
// spine chapters, FB2 <section><title>). wordIndex is where it starts in
// the same word-index space ReaderCubit paginates over - approximate for
// formats whose extraction reflows text, but close enough to jump to.
class Chapter {
  final String title;
  final int wordIndex;

  const Chapter({required this.title, required this.wordIndex});

  Map<String, dynamic> toJson() => {'title': title, 'wordIndex': wordIndex};

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        title: json['title'] as String,
        wordIndex: json['wordIndex'] as int,
      );
}
