class WordBucketEntry {
  final String word;
  final String translation;
  final String documentId;
  final String documentTitle;

  const WordBucketEntry({
    required this.word,
    required this.translation,
    required this.documentId,
    required this.documentTitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'documentId': documentId,
      'documentTitle': documentTitle,
    };
  }

  factory WordBucketEntry.fromJson(Map<String, dynamic> json) {
    return WordBucketEntry(
      word: json['word'] as String,
      translation: json['translation'] as String,
      documentId: json['documentId'] as String,
      documentTitle: json['documentTitle'] as String,
    );
  }
}
