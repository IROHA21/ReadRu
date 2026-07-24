import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
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
    return BlocProvider(
      create: (_) => getIt<LibraryCubit>()..loadDocument(document),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
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
                LibraryLoading() => const Center(child: CircularProgressIndicator()),
                LibraryLoaded() => ReaderView(
                    text: state.text,
                    initialWordIndex: document.lastWordIndex,
                    initialTappedWordIndices: document.tappedWordIndices.toSet(),
                    onProgressChanged: (lastWordIndex, progress, tappedWordIndices) {
                      return getIt<LibraryRepository>().updateReadingProgress(
                        Document(
                          id: document.id,
                          title: document.title,
                          filepath: document.filepath,
                          format: document.format,
                          progress: progress,
                          lastWordIndex: lastWordIndex,
                          tappedWordIndices: tappedWordIndices.toList(),
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
