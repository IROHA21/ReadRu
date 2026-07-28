import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/core/widgets/page_turn_loader.dart';
import 'package:read_ru/features/word_bucket/domain/entities/word_bucket_entry.dart';
import 'package:read_ru/features/word_bucket/presentation/cubit/word_bucket_cubit.dart';
import 'package:read_ru/features/word_bucket/presentation/cubit/word_bucket_state.dart';

class WordBucketScreen extends StatefulWidget {
  const WordBucketScreen({super.key});

  @override
  State<WordBucketScreen> createState() => _WordBucketScreenState();
}

class _WordBucketScreenState extends State<WordBucketScreen> {
  bool _groupByBook = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocProvider(
      create: (_) => getIt<WordBucketCubit>()..loadEntries(),
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          title: const Text('Word Bucket'),
          actions: [
            IconButton(
              icon: Icon(_groupByBook ? Icons.view_list : Icons.menu_book),
              tooltip: _groupByBook ? 'Show all words' : 'Group by book',
              onPressed: () => setState(() => _groupByBook = !_groupByBook),
            ),
          ],
        ),
        body: BlocConsumer<WordBucketCubit, WordBucketState>(
          listener: (context, state) {
            if (state is WordBucketError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return switch (state) {
              WordBucketInitial() || WordBucketLoading() || WordBucketError() =>
                const Center(child: PageTurnLoader()),
              WordBucketLoaded() => state.entries.isEmpty
                  ? _EmptyState(colors: colors)
                  : (_groupByBook
                      ? _GroupedList(entries: state.entries, colors: colors)
                      : _FlatList(entries: state.entries, colors: colors)),
            };
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Tap words while reading to save their translations here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary),
        ),
      ),
    );
  }
}

class _FlatList extends StatelessWidget {
  final List<WordBucketEntry> entries;
  final AppColors colors;
  const _FlatList({required this.entries, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: entries.length,
      itemBuilder: (context, index) => _EntryTile(entry: entries[index], colors: colors),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<WordBucketEntry> entries;
  final AppColors colors;
  const _GroupedList({required this.entries, required this.colors});

  @override
  Widget build(BuildContext context) {
    final byBook = <String, List<WordBucketEntry>>{};
    for (final entry in entries) {
      byBook.putIfAbsent(entry.documentTitle, () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        for (final book in byBook.keys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              book,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          for (final entry in byBook[book]!) _EntryTile(entry: entry, colors: colors),
        ],
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final WordBucketEntry entry;
  final AppColors colors;
  const _EntryTile({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${entry.documentId}_${entry.word}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<WordBucketCubit>().removeEntry(entry),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.word,
                style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            Icon(Icons.arrow_forward, size: 16, color: colors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.translation,
                style: TextStyle(color: colors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
