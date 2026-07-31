import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/purchases/presentation/remove_ads_manager.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({super.key});

  @override
  State<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  final _manager = getIt<RemoveAdsManager>();
  StreamSubscription<RemoveAdsPurchaseEvent>? _eventSubscription;
  ProductDetails? _product;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _eventSubscription = _manager.events.listen(_onEvent);
    _manager.queryProduct().then((product) {
      if (mounted) setState(() => _product = product);
    });
  }

  void _onEvent(RemoveAdsPurchaseEvent event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (event) {
      RemoveAdsPurchaseEvent.success => l10n.removeAdsPurchaseSuccessMessage,
      RemoveAdsPurchaseEvent.canceled => l10n.removeAdsPurchaseCanceledMessage,
      RemoveAdsPurchaseEvent.error => l10n.removeAdsPurchaseFailedMessage,
      RemoveAdsPurchaseEvent.nothingToRestore => l10n.removeAdsNothingToRestoreMessage,
    };
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    await _manager.buy();
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    await _manager.restore();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(l10n.removeAdsScreenTitle),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _manager.adsRemovedListenable,
        builder: (context, adsRemoved, _) {
          if (adsRemoved) {
            return _AlreadyRemovedView(colors: colors, l10n: l10n);
          }
          return _PurchaseView(
            colors: colors,
            l10n: l10n,
            product: _product,
            busy: _busy,
            onBuy: _buy,
            onRestore: _restore,
          );
        },
      ),
    );
  }
}

class _AlreadyRemovedView extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;

  const _AlreadyRemovedView({required this.colors, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: colors.accent, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.removeAdsRemovedMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseView extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;
  final ProductDetails? product;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  const _PurchaseView({
    required this.colors,
    required this.l10n,
    required this.product,
    required this.busy,
    required this.onBuy,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.block, color: colors.accent, size: 56),
          const SizedBox(height: 16),
          Text(
            l10n.removeAdsDescription,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: busy ? null : onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    product != null
                        ? '${l10n.removeAdsButtonLabel} - ${product!.price}'
                        : l10n.removeAdsButtonLabel,
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy ? null : onRestore,
            child: Text(l10n.removeAdsRestoreButtonLabel, style: TextStyle(color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
