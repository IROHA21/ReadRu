import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_ru/features/settings/domain/reader_settings.dart';

class SettingsLocalDataSource {
  static const _key = 'reader_settings';

  Future<ReaderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return ReaderSettings.defaults;
    }
    return ReaderSettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Future<void> saveSettings(ReaderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
