/// One interstitial-ad network, behind a network-agnostic interface so the
/// rest of the app never has to know whether it's talking to AdMob or
/// Yandex - see InterstitialAdManager for the network selection.
abstract class InterstitialAdService {
  /// Starts the underlying SDK. Call once, before the first load().
  Future<void> initialize();

  /// Fetches an ad in the background so it's ready by the time
  /// showIfReady() is called. Safe to call repeatedly - no-ops while a
  /// load is already in flight or a loaded ad is already waiting.
  Future<void> load();

  /// Shows the loaded ad, if any, and starts loading the next one once
  /// it's dismissed. If nothing is loaded yet, kicks off a load for next
  /// time and returns immediately without showing anything - callers
  /// should never block navigation on an ad being ready. Returns whether
  /// an ad was actually shown, so callers can count real impressions
  /// rather than just calls.
  Future<bool> showIfReady();
}
