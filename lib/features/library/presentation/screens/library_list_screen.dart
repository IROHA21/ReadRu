import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/core/widgets/page_turn_loader.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_state.dart';
import 'package:read_ru/features/library/presentation/screens/document_info_screen.dart';
import 'package:read_ru/features/library/presentation/screens/document_viewer_screen.dart';
import 'package:read_ru/features/settings/presentation/screens/settings_screen.dart';
import 'package:read_ru/features/word_bucket/presentation/screens/word_bucket_screen.dart';

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
                    'Library',
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
                        tooltip: 'Word Bucket',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WordBucketScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: colors.textPrimary),
                        tooltip: 'Settings',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
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
        onPressed: () => context.read<LibraryListCubit>().addDocument(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _LibraryListContent extends StatelessWidget {
  final List<Document> documents;

  const _LibraryListContent({required this.documents});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
              'Add your first document to begin reading.',
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _DocumentAction.info,
                  child: Text('Info'),
                ),
                PopupMenuItem(
                  value: _DocumentAction.rename,
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  value: _DocumentAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDocument(BuildContext context, Document document) async {
    final cubit = context.read<LibraryListCubit>();
    final controller = TextEditingController(text: document.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename book'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('"${document.title}" will be removed from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
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
