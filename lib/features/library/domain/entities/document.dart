import 'package:read_ru/features/library/domain/entities/chapter.dart';

class Document{
  final String id;
  final String title;
  final String filepath;
  final DocumentFormat format;
  final double progress;

  final int lastWordIndex;
  final List<int> tappedWordIndices;
  // Word index -> translation, so reopening a book doesn't re-hit the
  // translation API for words that were already tapped and translated.
  final Map<int, String> translatedWords;
  // Cover image extracted from the book file itself (epub/mobi/fb2 carry
  // one; pdf/txt don't), base64-encoded so it fits the same JSON blob as
  // everything else. Null whenever the format has none or extraction failed.
  final String? coverImageBase64;
  // Chapter/section headings pulled from the book's own structure, if any
  // (epub/fb2; mobi and pdf/txt get an empty list).
  final List<Chapter> chapters;
  // Metadata straight from the book file itself (epub/mobi/fb2) - null
  // whenever the format has none or extraction failed.
  final String? author;
  final String? description;
  final String? language;

  Document({
    required this.id,
    required this.title,
    required this.filepath,
    required this.format,
    required this.progress,
    this.lastWordIndex = 0,
    this.tappedWordIndices = const[],
    this.translatedWords = const {},
    this.coverImageBase64,
    this.chapters = const [],
    this.author,
    this.description,
    this.language,
  });

  Document copyWith({
    String? title,
    double? progress,
    int? lastWordIndex,
    List<int>? tappedWordIndices,
    Map<int, String>? translatedWords,
    String? coverImageBase64,
    List<Chapter>? chapters,
    String? author,
    String? description,
    String? language,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      filepath: filepath,
      format: format,
      progress: progress ?? this.progress,
      lastWordIndex: lastWordIndex ?? this.lastWordIndex,
      tappedWordIndices: tappedWordIndices ?? this.tappedWordIndices,
      translatedWords: translatedWords ?? this.translatedWords,
      coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
      chapters: chapters ?? this.chapters,
      author: author ?? this.author,
      description: description ?? this.description,
      language: language ?? this.language,
    );
  }
   // Document to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filepath': filepath,
      'format': format.name,
      'progress': progress,

      'lastWordIndex': lastWordIndex,
      'tappedWordIndices': tappedWordIndices,
      // JSON object keys must be strings - word indices are re-parsed as
      // ints on the way back in.
      'translatedWords': translatedWords.map((index, translation) => MapEntry(index.toString(), translation)),
      'coverImageBase64': coverImageBase64,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'author': author,
      'description': description,
      'language': language,
    };
  }
  // json to Document
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      title: json['title'] as String,
      filepath: json['filepath'] as String,
      format:
      DocumentFormat.values.byName(json['format'] as
      String),
      progress: json['progress'] as double,

      lastWordIndex: json['lastWordIndex'] as int? ?? 0,
      tappedWordIndices: (json['tappedWordIndices'] as List<dynamic>?)?.cast<int>() ?? const [],
      translatedWords: (json['translatedWords'] as Map<String, dynamic>?)?.map(
            (index, translation) => MapEntry(int.parse(index), translation as String),
          ) ??
          const {},
      coverImageBase64: json['coverImageBase64'] as String?,
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      author: json['author'] as String?,
      description: json['description'] as String?,
      language: json['language'] as String?,
    );
  }


}

enum DocumentFormat {
  pdf,
  epub,
  mobi,
  fb2,
  txt
}


