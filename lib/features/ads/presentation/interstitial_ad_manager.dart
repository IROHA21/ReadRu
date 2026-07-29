import 'package:read_ru/features/ads/data/google_interstitial_ad_service.dart';
import 'package:read_ru/features/ads/data/yandex_interstitial_ad_service.dart';
import 'package:read_ru/features/ads/domain/ad_region.dart';
import 'package:read_ru/features/ads/domain/interstitial_ad_service.dart';

/// Picks Yandex for CIS countries and Google AdMob everywhere else (see
/// ad_region.dart), then behaves like a single InterstitialAdService to the
/// rest of the app - callers never need to know which network is active.
class InterstitialAdManager implements InterstitialAdService {
  InterstitialAdManager({InterstitialAdService? service})
      : _service = service ??
            (isCisCountry(deviceCountryCode())
                ? YandexInterstitialAdService()
                : GoogleInterstitialAdService());

  final InterstitialAdService _service;

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<void> load() => _service.load();

  @override
  Future<void> showIfReady() => _service.showIfReady();
}
