

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

class LibraryLocalDataSource {

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) {
      return null;
    }
    return result.files.single;
  }


  Future<String> extractPdfText(String filePath) async
  {
    final bytes = File(filePath).readAsBytesSync(); // opens the file as bites and reads raw conetent

    final document = PdfDocument(inputBytes: bytes); //hand those bytes to Syncfusion so it can open the PDF

    final text = PdfTextExtractor(document).extractText(); //extract the text from that document

    document.dispose();
    return text;

  }

}