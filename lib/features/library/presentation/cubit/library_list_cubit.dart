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

  Future<void> addDocument() async {
    try {
      final document = await
      repository.pickDocument();
      if (document == null) {
        return;
      }
      await loadLibrary();
    } catch (e) {
      emit(LibraryListError(e.toString()));
      await loadLibrary();

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
        emit(LibraryListError('A book named "$trimmed" already exists'));
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
