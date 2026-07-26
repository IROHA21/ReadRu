



class Document{
  final String id;
  final String title;
  final String filepath;
  final DocumentFormat format;
  final double progress;

  final int lastWordIndex;
  final List<int> tappedWordIndices;

  Document({
    required this.id,
    required this.title,
    required this.filepath,
    required this.format,
    required this.progress,
    this.lastWordIndex = 0,
    this.tappedWordIndices = const[],
  });
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


