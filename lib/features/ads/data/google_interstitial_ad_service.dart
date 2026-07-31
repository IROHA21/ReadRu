import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:read_ru/features/ads/domain/interstitial_ad_service.dart';

// Google's own public TEST interstitial ad unit IDs - always fill, never
// generate real revenue or risk an account flag for invalid traffic while
// the app is still in testing. Swap for the real AdMob unit ID before
// release.
const String _testAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
const String _testAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910';

class GoogleInterstitialAdService implements InterstitialAdService {
  InterstitialAd? _ad;
  bool _loading = false;

  String get _adUnitId => Platform.isAndroid ? _testAdUnitIdAndroid : _testAdUnitIdIOS;

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<void> load() async {
    if (_loading || _ad != null) return;
    _loading = true;
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              unawaited(load());
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _ad = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loading = false;
        },
      ),
    );
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
