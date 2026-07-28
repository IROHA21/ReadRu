
import 'package:read_ru/features/library/domain/entities/document.dart';

abstract class LibraryRepository {

    // select books in user's storage
    Future<Document?> pickDocument();


    // extract the string from books
    Future<String> extractText(Document document);

    // get the books present
    Future<List<Document>> getLibrary();

    // delete one document
    Future<void> deleteDocument(Document document);

    // rename one document
    Future<void> renameDocument(Document document, String newTitle);

    // save progress
    Future<void> updateReadingProgress(Document document);

}