
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/library/presentation/cubit/library_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_state.dart';
import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LibraryCubit>(),
        child: Builder(
          builder: (context) => Scaffold(
        body: SafeArea(
          child: BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              return switch (state) {
                LibraryInitial() => const Center(child: Text('No document loaded')),
                LibraryLoading() => const Center(child: CircularProgressIndicator()),
                LibraryLoaded() => Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(child: Text(state.text)),
                  ),
                LibraryError() => Center(child: Text(state.message)),
              };
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.read<LibraryCubit>().pickAndLoadDocument(),
          child: const Icon(Icons.add),
        ),
      ),
        ),
    );
  }
}
