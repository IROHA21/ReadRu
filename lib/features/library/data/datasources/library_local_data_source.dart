

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'package:epubx/epubx.dart';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:kindle_unpack/kindle_unpack.dart';
import 'package:read_ru/features/library/data/utils/html_to_plain_text.dart';

class LibraryLocalDataSource {

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) {
      return null;
    }
    return result.files.single;
  }

  //pdf
  Future<String> extractPdfText(String filePath) async
  {
    final bytes = await File(filePath).readAsBytes(); // opens the file as bites and reads raw conetent

    final document = PdfDocument(inputBytes: bytes); //hand those bytes to Syncfusion so it can open the PDF

    final text = PdfTextExtractor(document).extractText(); //extract the text from that document

    document.dispose();
    return text;

  }

  // txt
  Future<String> extractTxtText(String filePath) async {
    return File(filePath).readAsString();
  }

  //epub
  Future<String> extractEpubText(String filePath) async{
    final bytes = await File(filePath).readAsBytes();
    final book = await EpubReader.readBook(bytes);

    final buffer = StringBuffer();
    for (final chapter in book.Chapters ?? []) {
      buffer.writeln(chapter.HtmlContent ?? '');
    }

    return htmlToPlainText(buffer.toString());
  }

  //mobi
  Future<String> extractMobiText(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final book = KindleBook.fromBytes(bytes);
    final buffer = StringBuffer();
    for (final part in book.parts) {
      buffer.writeln(utf8.decode(part.bytes, allowMalformed: true));
    }

    return htmlToPlainText(buffer.toString());
  }

  //fb2
  Future<String> extractFb2Text(String filePath) async {
    final content = await File(filePath).readAsString();
    final document = XmlDocument.parse(content);

    // FB2 marks each paragraph with its own <p>, but innerText on <body>
    // alone concatenates them with no separator - join per-<p> instead so
    // paragraph breaks (blank line, same contract as htmlToPlainText) survive.
    final paragraphs = document
        .findAllElements('p')
        .map((p) => p.innerText.trim())
        .where((p) => p.isNotEmpty);

    return paragraphs.join('\n\n');
  }
}