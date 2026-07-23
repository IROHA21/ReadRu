import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/presentation/cubit/library_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_state.dart';

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
                LibraryLoaded() => Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(child: Text(state.text)),
                  ),

              };
            },
          ),
        ),
      ),
    );
  }
}
