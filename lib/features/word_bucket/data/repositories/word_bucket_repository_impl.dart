import 'package:read_ru/features/word_bucket/data/datasources/word_bucket_local_data_source.dart';
import 'package:read_ru/features/word_bucket/domain/entities/word_bucket_entry.dart';
import 'package:read_ru/features/word_bucket/domain/repositories/word_bucket_repository.dart';

class WordBucketRepositoryImpl implements WordBucketRepository {
  final WordBucketLocalDataSource dataSource;

  WordBucketRepositoryImpl(this.dataSource);

  @override
  Future<List<WordBucketEntry>> getEntries() {
    return dataSource.getEntries();
  }

  @override
  Future<void> addEntry(WordBucketEntry entry) async {
    final entries = await dataSource.getEntries();

    // Same word tapped again in the same book just refreshes the
    // translation in place instead of piling up duplicates.
    final index = entries.indexWhere(
      (e) => e.word == entry.word && e.documentId == entry.documentId,
    );
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }

    await dataSource.saveEntries(entries);
  }

  @override
  Future<void> removeEntry(WordBucketEntry entry) async {
    final entries = await dataSource.getEntries();
    entries.removeWhere(
      (e) => e.word == entry.word && e.documentId == entry.documentId,
    );
    await dataSource.saveEntries(entries);
  }

  @override
  Future<void> removeEntriesForDocument(String documentId) async {
    final entries = await dataSource.getEntries();
    entries.removeWhere((e) => e.documentId == documentId);
    await dataSource.saveEntries(entries);
  }
}
