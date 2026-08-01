import 'package:read_ru/features/word_bucket/domain/entities/word_bucket_entry.dart';

abstract class WordBucketRepository {
  Future<List<WordBucketEntry>> getEntries();
  Future<void> addEntry(WordBucketEntry entry);
  Future<void> removeEntry(WordBucketEntry entry);
  // Called when a book is deleted from the library - its saved words
  // wouldn't be reachable from anywhere afterward anyway.
  Future<void> removeEntriesForDocument(String documentId);
}
