
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/features/library/data/datasources/library_storage_data_source.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/library/data/datasources/library_local_data_source.dart';
import 'package:read_ru/features/library/domain/entities/chapter.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/domain/normalize_extracted_text.dart';
import 'package:read_ru/features/onboarding/data/datasources/onboarding_local_data_source.dart';

class LibraryRepositoryImpl implements LibraryRepository {

// class LibraryRepositoryImpl implements LibraryRepository {
//     final LibraryLocalDataSource dataSource =
//   LibraryLocalDataSource();
//   }  this is welding it , but we want to be able to replace it for unit tests
  final LibraryLocalDataSource dataSource;
  final LibraryStorageDataSource storageDataSource;
  final OnboardingLocalDataSource onboardingDataSource;

  LibraryRepositoryImpl(this.dataSource, this.storageDataSource, this.onboardingDataSource);

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

    final filenameTitle = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');

    // Only epub/mobi/fb2 carry metadata worth extracting - pdf/txt skip
    // straight to the filename title with no isolate spawned.
    final metadata = format == DocumentFormat.pdf || format == DocumentFormat.txt
        ? null
        : await compute(_extractMetadata, (file.path!, format));

    final title = metadata?.title ?? filenameTitle;

    // No format-provided language (pdf/txt, or extraction found none) -
    // fall back to whatever the user said their books are in during
    // onboarding. Still overridable later from the book's Info screen.
    String? language = metadata?.language;
    if (language == null) {
      final onboarding = await onboardingDataSource.getSettings();
      if (onboarding.bookLanguages.isNotEmpty) {
        language = onboarding.bookLanguages.first.bcpCode;
      }
    }

    final library = await storageDataSource.getSavedDocuments();

    final alreadyExists = library.any((doc) =>
    doc.title == title);

    if (alreadyExists) {
      throw Exception('Already added');
    }

    final document = Document(
      id: file.path!,
      title: title,
      filepath: file.path!,
      format: format,
      progress: 0,
      coverImageBase64: metadata?.coverImageBase64,
      chapters: metadata?.chapters ?? const [],
      author: metadata?.author,
      description: metadata?.description,
      language: language,
    );


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
  Future<void> renameDocument(Document document, String newTitle) async {
    final library = await storageDataSource.getSavedDocuments();
    final index = library.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;
    library[index] = document.copyWith(title: newTitle);
    await storageDataSource.saveDocuments(library);
  }

  @override
  Future<void> setDocumentLanguage(Document document, String? languageCode) async {
    final library = await storageDataSource.getSavedDocuments();
    final index = library.indexWhere((doc) => doc.id == document.id);
    if (index == -1) return;

    // Built directly, not via copyWith - copyWith can't set a field back to
    // null (its `?? this.x` pattern treats null as "leave unchanged"), and
    // clearing the override needs to be possible here.
    final current = library[index];
    library[index] = Document(
      id: current.id,
      title: current.title,
      filepath: current.filepath,
      format: current.format,
      progress: current.progress,
      lastWordIndex: current.lastWordIndex,
      tappedWordIndices: current.tappedWordIndices,
      translatedWords: current.translatedWords,
      coverImageBase64: current.coverImageBase64,
      chapters: current.chapters,
      author: current.author,
      description: current.description,
      language: languageCode,
    );
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

/// Runs inside the isolate, same reasoning as [_extractAndNormalize] -
/// parsing an epub/mobi/fb2 file just to pull its metadata out is still
/// real CPU work and shouldn't block the Library screen while adding a book.
Future<BookMetadata> _extractMetadata((String, DocumentFormat) args) async {
  final (filepath, format) = args;
  final dataSource = LibraryLocalDataSource();

  switch (format) {
    case DocumentFormat.epub:
      return dataSource.extractEpubMetadata(filepath);
    case DocumentFormat.mobi:
      return dataSource.extractMobiMetadata(filepath);
    case DocumentFormat.fb2:
      return dataSource.extractFb2Metadata(filepath);
    case DocumentFormat.pdf:
    case DocumentFormat.txt:
      // Never actually called for these (see the caller's guard) - kept
      // only so the switch stays exhaustive.
      return (
        title: null,
        author: null,
        description: null,
        language: null,
        coverImageBase64: null,
        chapters: const <Chapter>[],
      );
  }
}