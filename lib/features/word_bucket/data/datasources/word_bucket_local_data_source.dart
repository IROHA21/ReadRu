import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_ru/features/word_bucket/domain/entities/word_bucket_entry.dart';

class WordBucketLocalDataSource {
  static const _key = 'word_bucket_entries';

  Future<List<WordBucketEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((json) => WordBucketEntry.fromJson(json)).toList();
  }

  Future<void> saveEntries(List<WordBucketEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
