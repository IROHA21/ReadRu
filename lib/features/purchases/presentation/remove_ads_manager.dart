import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:read_ru/features/purchases/data/remove_ads_local_data_source.dart';

/// The one-time "Remove Ads" product id - needs a matching product actually
/// configured in Play Console / App Store Connect before real purchases can
/// go through; until then this is just the identifier the code looks for.
const String removeAdsProductId = 'remove_ads';

/// Outcome of a buy()/restore() attempt, for the Remove Ads screen to show
/// a snackbar without polling state itself.
enum RemoveAdsPurchaseEvent { success, canceled, error, nothingToRestore }

/// Tracks whether the user has bought "Remove Ads", checked against the
/// store once (restorePurchases) and then cached locally - once true,
/// nothing here ever hits the store API again, since a purchase this app
/// sells doesn't expire or need re-checking.
class RemoveAdsManager {
  RemoveAdsManager(this._dataSource);

  final RemoveAdsLocalDataSource _dataSource;
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _adsRemovedNotifier = ValueNotifier<bool>(false);
  final _eventController = StreamController<RemoveAdsPurchaseEvent>.broadcast();

  /// For the Remove Ads screen to rebuild the moment a purchase completes.
  ValueListenable<bool> get adsRemovedListenable => _adsRemovedNotifier;
  bool get adsRemoved => _adsRemovedNotifier.value;

  /// Fires once per buy()/restore() attempt that reaches a final state.
  Stream<RemoveAdsPurchaseEvent> get events => _eventController.stream;

  /// Call once at app startup. Loads the cached flag first; if ads were
  /// never confirmed removed, listens for purchase updates and asks the
  /// store once whether this account already owns the product (covers a
  /// reinstall, or a purchase made from a different device on the same
  /// store account).
  Future<void> initialize() async {
    _adsRemovedNotifier.value = await _dataSource.getAdsRemoved();
    if (adsRemoved) return;

    if (!await _iap.isAvailable()) return;
    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      // Must not throw here: this runs before ad SDK init in main.dart, and
      // an uncaught error would leave ads never initialized for the whole
      // session. Worst case, a genuine owner of the purchase just sees ads
      // until the next launch retries the restore.
      debugPrint('RemoveAdsManager.initialize restore failed: $e');
    }
  }

  /// Looks up the store's price/title for the product, for display on the
  /// Remove Ads screen. Returns null if the store is unavailable or the
  /// product isn't registered yet.
  Future<ProductDetails?> queryProduct() async {
    if (!await _iap.isAvailable()) return null;
    final response = await _iap.queryProductDetails({removeAdsProductId});
    return response.productDetails.firstOrNull;
  }

  /// Call every time an interstitial ad is actually shown. Returns true on
  /// every 3rd impression (3rd, 6th, 9th, ...) - callers use that as the
  /// signal to show the "remove ads" upsell. No-ops once ads are already
  /// removed.
  Future<bool> recordAdShown() async {
    if (adsRemoved) return false;
    final count = await _dataSource.incrementAdsShownCount();
    return count % 3 == 0;
  }

  /// True only for the user's very first book open ever - callers use this
  /// to skip the "before read" ad just that once. Persisted, so it stays
  /// consumed across app restarts, not just for the current session.
  Future<bool> consumeFirstBookOpen() => _dataSource.consumeFirstBookOpen();

  /// Starts a real purchase - call this from the "Remove Ads" button.
  Future<void> buy() async {
    if (adsRemoved) return;
    if (!await _iap.isAvailable()) {
      _eventController.add(RemoveAdsPurchaseEvent.error);
      return;
    }
    final product = await queryProduct();
    if (product == null) {
      _eventController.add(RemoveAdsPurchaseEvent.error);
      return;
    }
    _subscription ??= _iap.purchaseStream.listen(_handlePurchaseUpdates);
    try {
      // buyNonConsumable() resolves false (no throw) if the billing flow
      // never launched at all - e.g. Play Billing unreachable. In that case
      // no purchaseStream event ever arrives, so without this check the
      // screen's busy spinner would spin forever with no way to retry.
      final launched = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!launched) {
        _eventController.add(RemoveAdsPurchaseEvent.error);
      }
    } catch (e) {
      debugPrint('RemoveAdsManager.buy failed: $e');
      _eventController.add(RemoveAdsPurchaseEvent.error);
    }
  }

  /// Re-asks the store whether this account already owns the product -
  /// for the "Restore Purchases" button (reinstalls, new device, or an
  /// iOS App Store requirement).
  Future<void> restore() async {
    if (adsRemoved) return;
    if (!await _iap.isAvailable()) {
      _eventController.add(RemoveAdsPurchaseEvent.error);
      return;
    }
    _subscription ??= _iap.purchaseStream.listen(_handlePurchaseUpdates);
    try {
      await _iap.restorePurchases();
      // If the account owns the product, _handlePurchaseUpdates has already
      // set adsRemoved=true by the time this await returns (the restored
      // purchase is pushed onto the same stream before restorePurchases()
      // completes). If there was nothing to restore, purchaseStream never
      // fires at all - without this, the button's busy spinner would spin
      // forever with no feedback.
      if (!adsRemoved) {
        _eventController.add(RemoveAdsPurchaseEvent.nothingToRestore);
      }
    } catch (e) {
      debugPrint('RemoveAdsManager.restore failed: $e');
      _eventController.add(RemoveAdsPurchaseEvent.error);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // A failed/canceled purchase that never became a real Purchase object
      // (declined card, user backed out, billing error) arrives with an
      // empty productID - the plugin can't tie it to a product, but since
      // this app only ever buys one thing, it's always about this purchase.
      if (purchase.productID.isNotEmpty && purchase.productID != removeAdsProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Acknowledge with the store BEFORE caching "removed" locally. If
          // the app is killed between these two steps, the local flag is
          // still false, so restorePurchases() on next launch will see this
          // purchase again and retry completion. Persisting first would
          // risk the opposite: a crash leaves the store-side purchase
          // unacknowledged (Play auto-refunds unacknowledged purchases
          // after 3 days) while the cached flag alone means we'd never
          // check the store again to notice or fix it.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _adsRemovedNotifier.value = true;
          await _dataSource.setAdsRemoved(true);
          _eventController.add(RemoveAdsPurchaseEvent.success);
        case PurchaseStatus.error:
          _eventController.add(RemoveAdsPurchaseEvent.error);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.canceled:
          _eventController.add(RemoveAdsPurchaseEvent.canceled);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _adsRemovedNotifier.dispose();
    _eventController.close();
  }
}
