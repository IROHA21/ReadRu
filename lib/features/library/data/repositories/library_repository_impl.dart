
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/library/data/datasources/library_local_data_source.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';

class LibraryRepositoryImpl implements LibraryRepository {

// class LibraryRepositoryImpl implements LibraryRepository {
//     final LibraryLocalDataSource dataSource =
//   LibraryLocalDataSource();
//   }  this is welding it , but we want to be able to replace it for unit tests
  final LibraryLocalDataSource dataSource;
  LibraryRepositoryImpl(this.dataSource);

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
    return Document(id: file.path! , title: file.name, filepath: file.path!, format: format);

  }


  @override
  Future<String> extractText(Document document) async
  {

    switch (document.format) {
      case DocumentFormat.pdf:
        return dataSource.extractPdfText(document.filepath);
      default: throw UnimplementedError('${document.format} not supported yet');
    }


  }

}