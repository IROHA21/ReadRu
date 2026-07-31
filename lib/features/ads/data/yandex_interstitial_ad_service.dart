import 'dart:async';
import 'package:yandex_mobileads/mobile_ads.dart' as yandex;
import 'package:read_ru/features/ads/domain/interstitial_ad_service.dart';

// Yandex's own public demo interstitial ad unit - always fills with a
// placeholder creative, no real ad account needed while testing. Swap for
// the real Yandex ad unit ID before release.
const String _demoAdUnitId = 'demo-interstitial-yandex';

class YandexInterstitialAdService implements InterstitialAdService {
  final _loader = yandex.InterstitialAdLoader();
  yandex.InterstitialAd? _ad;
  bool _loading = false;

  @override
  Future<void> initialize() async {
    await yandex.YandexAds.initialize();
  }

  @override
  Future<void> load() async {
    if (_loading || _ad != null) return;
    _loading = true;
    try {
      final ad = await _loader.loadAd(adRequest: const yandex.AdRequest(adUnitId: _demoAdUnitId));
      _ad = ad;
      await ad.setAdEventListener(
        eventListener: yandex.InterstitialAdEventListener(
          onAdDismissed: () {
            _ad = null;
            unawaited(load());
          },
          onAdFailedToShow: (_) {
            _ad = null;
          },
        ),
      );
    } catch (_) {
      // Load failed - showIfReady() just no-ops next time it's called.
    } finally {
      _loading = false;
    }
  }

  @override
  Future<bool> showIfReady() async {
    final ad = _ad;
    if (ad == null) {
      unawaited(load());
      return false;
    }
    _ad = null;
    await ad.show();
    return true;
  }
}
