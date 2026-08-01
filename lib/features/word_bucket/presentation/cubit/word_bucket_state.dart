import 'package:read_ru/features/word_bucket/domain/entities/word_bucket_entry.dart';

sealed class WordBucketState {}

class WordBucketInitial extends WordBucketState {}

class WordBucketLoading extends WordBucketState {}

class WordBucketLoaded extends WordBucketState {
  final List<WordBucketEntry> entries;
  WordBucketLoaded(this.entries);
}

class WordBucketError extends WordBucketState {
  final String message;
  WordBucketError(this.message);
}
