import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'library_state.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';



class LibraryCubit extends Cubit<LibraryState>{
  final LibraryRepository repository;
  LibraryCubit(this.repository) : super(LibraryInitial());




  Future<void> pickAndLoadDocument() async {

    emit(LibraryLoading());
    try {
      final document = await repository.pickDocument();

      if (document == null) {
        emit(LibraryInitial());
        return;
      }

      final text = await repository.extractText(document);
      emit(LibraryLoaded(text));
    } catch (e) {
      emit(LibraryError(e.toString()));
      emit(LibraryInitial());
    }
  }



  Future<void> loadDocument(Document document) async {
    emit(LibraryLoading());
    try {
      final text = await
      repository.extractText(document);
      emit(LibraryLoaded(text));
    } catch (e) {
      emit(LibraryError(e.toString()));
      emit(LibraryInitial());
    }
  }


}
