import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/core/widgets/page_turn_loader.dart';
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

class _LibraryListView extends StatelessWidget {
  const _LibraryListView();

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
                },
                builder: (context, state) {
                  return switch (state) {
                    LibraryListInitial() || LibraryListLoading() || LibraryListError() =>
                      const Center(child: PageTurnLoader()),
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
          await _checkLanguagePack(context, document);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // A book's language pack (and the user's own spoken-language pack, since
  // translation needs both ends downloaded) might not be on-device yet -
  // offer to fetch it right away instead of leaving tap-to-translate
  // silently falling back to Yandex (or failing outright) until noticed.
  Future<void> _checkLanguagePack(BuildContext context, Document document) async {
    final bookLanguage = translateLanguageFromCode(document.language);
    if (bookLanguage == null) return;

    final spokenLanguage = getIt<OnboardingCubit>().state.spokenLanguage;
    final modelManager = OnDeviceTranslatorModelManager();

    final missing = <TranslateLanguage>[];
    if (!await modelManager.isModelDownloaded(bookLanguage.bcpCode)) missing.add(bookLanguage);
    if (spokenLanguage != null &&
        spokenLanguage != bookLanguage &&
        !await modelManager.isModelDownloaded(spokenLanguage.bcpCode)) {
      missing.add(spokenLanguage);
    }
    if (missing.isEmpty || !context.mounted) return;

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

    if (shouldDownload == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LanguagePackDownloadScreen(languages: missing)),
      );
    }
  }
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
