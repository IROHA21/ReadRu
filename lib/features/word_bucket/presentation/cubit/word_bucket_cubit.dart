import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/features/word_bucket/domain/entities/word_bucket_entry.dart';
import 'package:read_ru/features/word_bucket/domain/repositories/word_bucket_repository.dart';
import 'word_bucket_state.dart';

class WordBucketCubit extends Cubit<WordBucketState> {
  final WordBucketRepository repository;
  WordBucketCubit(this.repository) : super(WordBucketInitial());

  Future<void> loadEntries() async {
    emit(WordBucketLoading());
    try {
      final entries = await repository.getEntries();
      emit(WordBucketLoaded(entries));
    } catch (e) {
      emit(WordBucketError(e.toString()));
      emit(WordBucketLoaded([]));
    }
  }

  Future<void> removeEntry(WordBucketEntry entry) async {
    try {
      await repository.removeEntry(entry);
      await loadEntries();
    } catch (e) {
      emit(WordBucketError(e.toString()));
      await loadEntries();
    }
  }
}
