import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'library_list_state.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';

class LibraryListCubit extends Cubit<LibraryListState> {
  final LibraryRepository repository;
  LibraryListCubit(this.repository) : super(LibraryListInitial());


  Future<void> loadLibrary() async {
    emit(LibraryListLoading());
    try {
      final documents = await repository.getLibrary();
      emit(LibraryListLoaded(documents));
    } catch (e) {
      emit(LibraryListError(e.toString()));
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
    }
  }

  Future<void> removeDocument(Document document)
  async {
    try {
      await repository.deleteDocument(document);
      await loadLibrary();
    } catch (e) {
      emit(LibraryListError(e.toString()));
    }
  }
}