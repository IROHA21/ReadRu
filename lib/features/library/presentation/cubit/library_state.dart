

sealed class LibraryState {
}

class LibraryInitial extends LibraryState{

}

class LibraryLoading extends LibraryState{

}

class LibraryLoaded extends LibraryState{
  final String text;
  LibraryLoaded(this.text);
}

class LibraryError extends LibraryState{

  final String message;
  LibraryError(this.message);
}