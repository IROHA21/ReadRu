import 'dart:ui';

// Countries in the CIS (Commonwealth of Independent States) - Yandex's
// core ad market, where its fill rates/eCPM beat AdMob's. Everyone else
// defaults to Google. This is a device-locale heuristic (the phone's
// region setting), not real IP geolocation - there's no geolocation
// service wired into the app, and the region setting is a reasonable
// proxy for "which network actually has demand here" without one.
const Set<String> cisCountryCodes = {
  'RU', 'BY', 'KZ', 'AM', 'AZ', 'KG', 'MD', 'TJ', 'UZ', 'TM',
};

bool isCisCountry(String? countryCode) =>
    countryCode != null && cisCountryCodes.contains(countryCode.toUpperCase());

/// The device's region setting - used only to pick an ad network, never
/// tied to the app's interface language or the book being read.
String? deviceCountryCode() => PlatformDispatcher.instance.locale.countryCode;
