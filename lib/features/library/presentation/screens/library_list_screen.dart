import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_state.dart';
import 'package:read_ru/features/library/presentation/screens/document_viewer_screen.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Library',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: AppColors.textPrimary),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                        onPressed: () {},
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
                      const Center(child: CircularProgressIndicator()),
                    LibraryListLoaded() => _LibraryListContent(documents: state.documents),
                  };
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
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
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Add your first document to begin reading.',
              style: TextStyle(color: AppColors.textSecondary),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: document)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.thumbnailPlaceholder,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(document.progress * 100).round()}% · ${document.format.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: document.progress,
                      minHeight: 4,
                      backgroundColor: AppColors.progressTrack,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.textSecondary),
              onPressed: () => _confirmDelete(context, document),
            ),
          ],
        ),
      ),
    );
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
