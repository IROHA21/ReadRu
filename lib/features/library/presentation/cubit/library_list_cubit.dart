import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'library_list_state.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/word_bucket/domain/repositories/word_bucket_repository.dart';

class LibraryListCubit extends Cubit<LibraryListState> {
  final LibraryRepository repository;
  final WordBucketRepository wordBucketRepository;
  LibraryListCubit(this.repository, this.wordBucketRepository) : super(LibraryListInitial());


  Future<void> loadLibrary() async {
    emit(LibraryListLoading());
    try {
      final documents = await repository.getLibrary();
      emit(LibraryListLoaded(documents));
    } catch (e) {
      emit(LibraryListError(e.toString()));
      emit(LibraryListLoaded([]));
    }
  }

  // Returns the added document (for the screen to check its language
  // pack against) - null if the picker was cancelled or it failed.
  //
  // Drives the library body's own LibraryListLoading() state (the plain
  // centered PageTurnLoader, no dimmed barrier) for the whole pick+parse -
  // the same simple loading presentation the initial library load already
  // uses, rather than a separate dialog overlay stacked on top of it.
  Future<Document?> addDocument() async {
    emit(LibraryListLoading());
    try {
      final document = await repository.pickDocument();
      if (document == null) {
        await loadLibrary();
        return null;
      }
      final documents = await repository.getLibrary();
      emit(LibraryListLoaded(documents));
      return document;
    } catch (e) {
      emit(LibraryListError(e.toString()));
      await loadLibrary();
      return null;
    }
  }

  Future<void> removeDocument(Document document)
  async {
    try {
      await repository.deleteDocument(document);
      await wordBucketRepository.removeEntriesForDocument(document.id);
      await loadLibrary();
    } catch (e) {
      emit(LibraryListError(e.toString()));
      await loadLibrary();
    }
  }

  Future<void> renameDocument(Document document, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty || trimmed == document.title) return;

    try {
      final library = await repository.getLibrary();
      final alreadyExists = library.any((doc) => doc.id != document.id && doc.title == trimmed);
      if (alreadyExists) {
        emit(LibraryListError('A book named "$trimmed" already exists', duplicateTitle: trimmed));
        await loadLibrary();
        return;
      }

      await repository.renameDocument(document, trimmed);
      await loadLibrary();
    } catch (e) {
      emit(LibraryListError(e.toString()));
      await loadLibrary();
    }
  }
}
