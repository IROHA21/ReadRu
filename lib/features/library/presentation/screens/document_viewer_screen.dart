import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/core/widgets/page_turn_loader.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/library/presentation/cubit/library_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_state.dart';
import 'package:read_ru/features/reader/presentation/screens/reader_view.dart';

class DocumentViewerScreen extends StatelessWidget {
  final Document document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return BlocProvider(
      create: (_) => getIt<LibraryCubit>()..loadDocument(document),
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          title: Text(document.title),
        ),
        body: SafeArea(
          child: BlocConsumer<LibraryCubit, LibraryState>(

            listener: (context, state) {
              if (state is LibraryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              return switch (state) {
                LibraryInitial() || LibraryError() => const SizedBox(),
                LibraryLoading() => const Center(child: PageTurnLoader()),
                LibraryLoaded() => ReaderView(
                    text: state.text,
                    documentId: document.id,
                    documentTitle: document.title,
                    chapters: document.chapters,
                    initialWordIndex: document.lastWordIndex,
                    initialTappedWordIndices: document.tappedWordIndices.toSet(),
                    initialTranslatedWords: document.translatedWords,
                    onProgressChanged: (lastWordIndex, progress, tappedWordIndices, translatedWords) {
                      // copyWith, not a fresh Document(...) - a manual
                      // reconstruction silently drops any field it forgets
                      // to list (this is exactly how coverImageBase64 was
                      // getting wiped on every page turn/exit).
                      return getIt<LibraryRepository>().updateReadingProgress(
                        document.copyWith(
                          progress: progress,
                          lastWordIndex: lastWordIndex,
                          tappedWordIndices: tappedWordIndices.toList(),
                          translatedWords: translatedWords,
                        ),
                      );
                    },
                  ),

              };
            },
          ),
        ),
      ),
    );
  }
}
