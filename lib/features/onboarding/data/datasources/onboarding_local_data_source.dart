import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:read_ru/features/onboarding/domain/onboarding_settings.dart';

class OnboardingLocalDataSource {
  static const _key = 'onboarding_settings';

  Future<OnboardingSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return OnboardingSettings.defaults;
    }
    return OnboardingSettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Future<void> saveSettings(OnboardingSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
