import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/core/widgets/page_turn_loader.dart';
import 'package:read_ru/features/ads/presentation/interstitial_ad_manager.dart';
import 'package:read_ru/features/purchases/presentation/remove_ads_manager.dart';
import 'package:read_ru/features/purchases/presentation/screens/remove_ads_screen.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_state.dart';
import 'package:read_ru/features/library/presentation/screens/document_info_screen.dart';
import 'package:read_ru/features/library/presentation/screens/document_viewer_screen.dart';
import 'package:read_ru/features/onboarding/domain/supported_languages.dart';
import 'package:read_ru/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:read_ru/features/onboarding/presentation/screens/language_pack_download_screen.dart';
import 'package:read_ru/features/settings/presentation/screens/settings_screen.dart';
import 'package:read_ru/features/word_bucket/presentation/screens/word_bucket_screen.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

class LibraryListScreen extends StatelessWidget {
  const LibraryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LibraryListCubit>()..loadLibrary(),
      child: const _LibraryListView(),
    );
  }
}

class _LibraryListView extends StatefulWidget {
  const _LibraryListView();

  @override
  State<_LibraryListView> createState() => _LibraryListViewState();
}

class _LibraryListViewState extends State<_LibraryListView> {
  // Kept around so the Loading state can show the previous list dimmed
  // underneath the loader instead of blanking the screen to a bare
  // background - only ever updated from the listener below, right before
  // the builder that reads it runs for the same state emission.
  List<Document> _lastDocuments = const [];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.libraryTitle,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.translate, color: colors.textPrimary),
                        tooltip: l10n.wordBucketTooltip,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WordBucketScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: colors.textPrimary),
                        tooltip: l10n.settingsTitle,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<LibraryListCubit, LibraryListState>(
                listener: (context, state) {
                  if (state is LibraryListError) {
                    final duplicateTitle = state.duplicateTitle;
                    final message = duplicateTitle != null
                        ? AppLocalizations.of(context)!.bookAlreadyExists(duplicateTitle)
                        : state.message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                  if (state is LibraryListLoaded) {
                    _lastDocuments = state.documents;
                  }
                },
                builder: (context, state) {
                  return switch (state) {
                    LibraryListInitial() || LibraryListLoading() || LibraryListError() => Stack(
                        children: [
                          if (_lastDocuments.isNotEmpty)
                            _LibraryListContent(documents: _lastDocuments),
                          Positioned.fill(
                            child: AbsorbPointer(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.3),
                                child: const Center(child: PageTurnLoader()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    LibraryListLoaded() => _LibraryListContent(documents: state.documents),
                  };
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.accent,
        onPressed: () async {
          final cubit = context.read<LibraryListCubit>();
          final document = await cubit.addDocument();
          if (document == null || !context.mounted) return;
          await checkLanguagePack(context, document);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Dims the library screen and shows the same loading animation used for
// the library list itself while [action] runs. Picking and parsing a book
// (large EPUBs/PDFs especially) and the pre-open ad/language-pack check
// both used to run with zero feedback, making the screen look frozen -
// this makes that wait visible instead of silent.
Future<T> withLoadingOverlay<T>(BuildContext context, Future<T> Function() action) async {
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => const Center(child: PageTurnLoader()),
    ),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

// Shown every 3rd time an interstitial ad actually displays (see
// RemoveAdsManager.recordAdShown) - a soft nudge toward the one-time
// purchase, not a hard gate. "Remove Ads" goes straight to the purchase
// screen rather than through the Settings hub, since the user already
// said yes here.
Future<void> showRemoveAdsUpsell(BuildContext context) async {
  final product = await getIt<RemoveAdsManager>().queryProduct();
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final goToPurchase = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.removeAdsUpsellTitle),
      content: Text(
        product != null
            ? l10n.removeAdsUpsellContent(product.price)
            : l10n.removeAdsUpsellContentGeneric,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.close)),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.removeAdsButtonLabel)),
      ],
    ),
  );

  if (goToPurchase == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RemoveAdsScreen()),
    );
  }
}

// isModelDownloaded() is a native ML Kit call reached on every single book
// open - it must never be able to block opening a book for more than a
// moment, regardless of what's wrong on the native side (a slow check, a
// broken plugin registration, anything). Fails open (treats the model as
// ready) on error or timeout: a broken check shouldn't cost the user their
// ability to read, since translation itself already falls back to Yandex
// independently either way.
Future<bool> _isModelReady(OnDeviceTranslatorModelManager manager, String bcpCode) async {
  try {
    return await manager.isModelDownloaded(bcpCode).timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('checkLanguagePack: isModelDownloaded($bcpCode) failed, assuming ready: $e');
    return true;
  }
}

// A book's language pack (and the user's own spoken-language pack, since
// translation needs both ends downloaded) might not be on-device yet - ask
// every time a book is added or opened while either is still missing,
// instead of asking once and then leaving tap-to-translate to silently and
// permanently fall back to Yandex (or fail outright) if "Later" was picked.
//
// Returns whether the caller should proceed with what it was about to do
// (open the book). That's true when nothing was missing, or the user
// downloaded it; false when the user picked "Later" or dismissed the
// dialog - a book that can't translate offline shouldn't open silently,
// it should just back out to the library so the gap stays visible.
Future<bool> checkLanguagePack(BuildContext context, Document document) async {
  final bookLanguage = translateLanguageFromCode(document.language);
  if (bookLanguage == null) return true;

  final spokenLanguage = getIt<OnboardingCubit>().state.spokenLanguage;
  final modelManager = OnDeviceTranslatorModelManager();

  final missing = <TranslateLanguage>[];
  if (!await _isModelReady(modelManager, bookLanguage.bcpCode)) missing.add(bookLanguage);
  if (spokenLanguage != null &&
      spokenLanguage != bookLanguage &&
      !await _isModelReady(modelManager, spokenLanguage.bcpCode)) {
    missing.add(spokenLanguage);
  }
  if (missing.isEmpty) return true;
  if (!context.mounted) return false;

  final l10n = AppLocalizations.of(context)!;
  final shouldDownload = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.downloadLanguagePackTitle),
      content: Text(
        l10n.downloadLanguagePackContent(document.title, translateLanguageName(bookLanguage)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.later)),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.download)),
      ],
    ),
  );

  if (shouldDownload != true || !context.mounted) return false;

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => LanguagePackDownloadScreen(languages: missing)),
  );
  return true;
}

class _LibraryListContent extends StatelessWidget {
  final List<Document> documents;

  const _LibraryListContent({required this.documents});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        for (final document in documents) ...[
          Dismissible(
            key: ValueKey(document.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => context.read<LibraryListCubit>().removeDocument(document),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: _DocumentCard(document: document),
          ),
          const SizedBox(height: 12),
        ],
        if (documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: colors.textSecondary.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              l10n.libraryEmptyState,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final cubit = context.read<LibraryListCubit>();
        var showUpsell = false;
        // "Before read" interstitial - skipped entirely once Remove Ads is
        // purchased, and otherwise no-ops instantly if nothing's loaded
        // yet, so this never delays opening the book. Runs BEFORE the
        // loading overlay (rather than inside it) so our own dimmed
        // "AnyRead" dialog is never on screen at the same time as the ad
        // SDK's own full-screen overlay - the two competing simultaneously
        // was a plausible source of stray visual artifacts during the
        // transition between them.
        if (!getIt<RemoveAdsManager>().adsRemoved) {
          // Skip the ad entirely on the user's very first book open ever -
          // a first impression shouldn't be an ad before they've even seen
          // what the app does with a book open.
          final isFirstBookOpen = await getIt<RemoveAdsManager>().consumeFirstBookOpen();
          if (!isFirstBookOpen) {
            final adShown = await getIt<InterstitialAdManager>().showIfReady();
            if (adShown) showUpsell = await getIt<RemoveAdsManager>().recordAdShown();
          }
        }
        if (!context.mounted) return;
        final canOpen = await withLoadingOverlay(
          context,
          () => checkLanguagePack(context, document),
        );
        if (!canOpen || !context.mounted) return;
        if (showUpsell) {
          await showRemoveAdsUpsell(context);
          if (!context.mounted) return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: document)),
        );
        cubit.loadLibrary();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: document.coverImageBase64 != null
                  ? Image.memory(
                      base64Decode(document.coverImageBase64!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: colors.thumbnailPlaceholder,
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: colors.thumbnailPlaceholder,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(document.progress * 100).round()}% · ${document.format.name.toUpperCase()}',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: document.progress,
                      minHeight: 4,
                      backgroundColor: colors.progressTrack,
                      valueColor: AlwaysStoppedAnimation(colors.accent),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_DocumentAction>(
              icon: Icon(Icons.more_vert, color: colors.textSecondary),
              onSelected: (action) {
                switch (action) {
                  case _DocumentAction.info:
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DocumentInfoScreen(document: document)),
                    );
                  case _DocumentAction.rename:
                    _renameDocument(context, document);
                  case _DocumentAction.delete:
                    _confirmDelete(context, document);
                }
              },
              itemBuilder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return [
                  PopupMenuItem(
                    value: _DocumentAction.info,
                    child: Text(l10n.infoMenuItem),
                  ),
                  PopupMenuItem(
                    value: _DocumentAction.rename,
                    child: Text(l10n.renameMenuItem),
                  ),
                  PopupMenuItem(
                    value: _DocumentAction.delete,
                    child: Text(l10n.delete),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDocument(BuildContext context, Document document) async {
    final cubit = context.read<LibraryListCubit>();
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: document.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.renameBookTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.title),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.trim().isNotEmpty) {
      cubit.renameDocument(document, newTitle);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Document document) async {
    final cubit = context.read<LibraryListCubit>();
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteDocumentTitle),
        content: Text(l10n.deleteDocumentContent(document.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.removeDocument(document);
    }
  }
}

enum _DocumentAction { info, rename, delete }
