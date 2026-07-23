
import 'package:read_ru/features/library/domain/entities/document.dart';

abstract class LibraryRepository {
    Future<Document?> pickDocument();

    Future<String> extractText(Document document);


}