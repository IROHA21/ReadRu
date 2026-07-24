
import 'package:read_ru/features/library/data/datasources/library_storage_data_source.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/library/data/datasources/library_local_data_source.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';

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

    switch (document.format) {
      case DocumentFormat.pdf:
        return dataSource.extractPdfText(document.filepath);
      case DocumentFormat.txt:
        return dataSource.extractTxtText(document.filepath);
      case DocumentFormat.epub:
        return dataSource.extractEpubText(document.filepath);
      case DocumentFormat.mobi:
        return dataSource.extractMobiText(document.filepath);
      case DocumentFormat.fb2:
        return dataSource.extractFb2Text(document.filepath);
    }


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