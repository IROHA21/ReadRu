
import 'package:flutter/foundation.dart';
import 'package:read_ru/features/library/data/datasources/library_storage_data_source.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/library/data/datasources/library_local_data_source.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/domain/normalize_extracted_text.dart';

class LibraryRepositoryImpl implements LibraryRepository {

// class LibraryRepositoryImpl implements LibraryRepository {
//     final LibraryLocalDataSource dataSource =
//   LibraryLocalDataSource();
//   }  this is welding it , but we want to be able to replace it for unit tests
  final LibraryLocalDataSource dataSource;
  final LibraryStorageDataSource storageDataSource;

  LibraryRepositoryImpl(this.dataSource, this.storageDataSource);

  @override
  Future<Document?> pickDocument() async {
    final file = await dataSource.pickFile();

    if (file == null) {
      return null;
    }


    DocumentFormat format = switch(file.extension){
      'pdf' => DocumentFormat.pdf,
      'epub' => DocumentFormat.epub,
      'mobi' => DocumentFormat.mobi,
      'fb2' => DocumentFormat.fb2,
      'txt' => DocumentFormat.txt,
      _ => throw Exception('unsupported file format')
    };

    final title = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');

    final library = await storageDataSource.getSavedDocuments();

    final alreadyExists = library.any((doc) =>
    doc.title == title);

    if (alreadyExists) {
      throw Exception('Already added');
    }

    final document = Document(id: file.path!, title: title, filepath: file.path!, format: format, progress: 0);
    // return Document(id: file.path! , title: file.name, filepath: file.path!, format: format, progress: 0);


    library.add(document);

    await storageDataSource.saveDocuments(library);

    return document;

  }


  @override
  Future<String> extractText(Document document) async
  {
    // Parsing + normalizing is heavy synchronous CPU work - run it in a
    // separate isolate via compute() so the UI thread keeps painting (the
    // loading spinner actually spins instead of freezing).
    return compute(
      _extractAndNormalize,
      (document.filepath, document.format),
    );
  }

  @override
  Future<List<Document>> getLibrary() {
    return storageDataSource.getSavedDocuments();
  }

  @override
  Future<void> deleteDocument(Document document) async {
    final library = await storageDataSource.getSavedDocuments();
    library.removeWhere((doc) => doc.id == document.id);
    await storageDataSource.saveDocuments(library);
  }


  @override
  Future<void> updateReadingProgress(Document document) async{
    final library = await storageDataSource.getSavedDocuments();
    final index = library.indexWhere((doc) => doc.id == document.id);

    if (index == -1) return;

    library[index] = document;
    await storageDataSource.saveDocuments(library);

  }





}

/// Runs inside the isolate - compute() requires a top-level function, and
/// isolates share no memory with the main one, so this builds its own
/// data source (it's stateless, so nothing is lost).
Future<String> _extractAndNormalize((String, DocumentFormat) args) async {
  final (filepath, format) = args;
  final dataSource = LibraryLocalDataSource();

  final raw = switch (format) {
    DocumentFormat.pdf => await dataSource.extractPdfText(filepath),
    DocumentFormat.txt => await dataSource.extractTxtText(filepath),
    DocumentFormat.epub => await dataSource.extractEpubText(filepath),
    DocumentFormat.mobi => await dataSource.extractMobiText(filepath),
    DocumentFormat.fb2 => await dataSource.extractFb2Text(filepath),
  };

  return normalizeExtractedText(raw, format);
}