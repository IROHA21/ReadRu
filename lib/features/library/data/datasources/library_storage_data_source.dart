import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';

class LibraryStorageDataSource {
  static const _key = 'saved_documents';


  // load json doc
  Future<List<Document>> getSavedDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(jsonString);

    return decoded.map((json) => Document.fromJson(json)).toList();

  }

  // save json doc
  Future<void> saveDocuments(List<Document> documents) async {

    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(documents.map((doc) => doc.toJson()).toList());

    await prefs.setString(_key, jsonString);
  }


}