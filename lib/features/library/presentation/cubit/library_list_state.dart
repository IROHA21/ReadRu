import 'package:read_ru/features/library/domain/entities/document.dart';

sealed class LibraryListState {}

class LibraryListInitial extends LibraryListState{}

class LibraryListLoading extends LibraryListState{}

class LibraryListLoaded extends LibraryListState{

  final List<Document> documents;
  LibraryListLoaded(this.documents);
}

class LibraryListError extends LibraryListState{
  final String message;
  LibraryListError(this.message);
}