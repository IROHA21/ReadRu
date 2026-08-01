import 'package:shared_preferences/shared_preferences.dart';

class RemoveAdsLocalDataSource {
  static const _key = 'remove_ads_purchased';
  static const _adsShownCountKey = 'remove_ads_upsell_ad_count';
  static const _firstBookOpenedKey = 'first_book_already_opened';

  Future<bool> getAdsRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setAdsRemoved(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  /// Persisted across sessions, not just this app run - "every 3rd ad"
  /// should count real impressions over the app's whole lifetime, not
  /// reset every time the app is relaunched.
  Future<int> incrementAdsShownCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_adsShownCountKey) ?? 0) + 1;
    await prefs.setInt(_adsShownCountKey, next);
    return next;
  }

  /// Returns true (and persists it) only the very first time this is ever
  /// called for an install - every call after that returns false,
  /// permanently, even across app restarts. Lets the caller skip the
  /// "before read" ad on the user's very first book without a separate
  /// onboarding-only flag.
  Future<bool> consumeFirstBookOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyOpened = prefs.getBool(_firstBookOpenedKey) ?? false;
    if (alreadyOpened) return false;
    await prefs.setBool(_firstBookOpenedKey, true);
    return true;
  }
}
