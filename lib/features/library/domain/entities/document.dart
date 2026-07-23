



class Document{
  final String id;
  final String title;
  final String filepath;
  final DocumentFormat format;

  Document({
    required this.id,
    required this.title,
    required this.filepath,
    required this.format,
  });


}

enum DocumentFormat {
  pdf,
  epub,
  mobi,
  fb2,
  txt
}