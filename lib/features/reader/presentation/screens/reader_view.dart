import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/config/secrets.dart';
import 'package:read_ru/features/reader/domain/split_into_words.dart';
import 'package:read_ru/features/reader/presentation/cubit/reader_cubit.dart';
import 'package:read_ru/features/reader/presentation/cubit/reader_state.dart';
import 'package:read_ru/features/reader/presentation/layout/measured_pagination.dart';

// DIRTY TEST CODE - no repository, no error UI beyond a fallback string.
// Delete this whole block once Phase 3 builds the real TranslationRepository.
// Real key/folder live in secrets.dart (gitignored) - see secrets.example.dart.
final Map<String, String> _translationCache = {};

// Strips leading/trailing punctuation - \p{L}/\p{N} match any letter/number
// in any script (Cyrillic included), so this doesn't assume Latin text.
String _stripPunctuation(String word) {
  return word.replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '');
}

Future<String> _translateWord(String word) async {
  if (_translationCache.containsKey(word)) {
    return _translationCache[word]!;
  }
  try {
    final response = await http.post(
      Uri.parse('https://translate.api.cloud.yandex.net/translate/v2/translate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Api-Key $yandexTranslateApiKey',
      },
      body: jsonEncode({
        'folderId': yandexTranslateFolderId,
        'texts': [word],
        'sourceLanguageCode': 'ru',
        'targetLanguageCode': 'en',
      }),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final translated = (decoded['translations'] as List).first['text'] as String;
    _translationCache[word] = translated;
    return translated;
  } catch (e) {
    return '(failed)';
  }
}

class ReaderView extends StatelessWidget {
  final String text;
  final int initialWordIndex;
  final Set<int> initialTappedWordIndices;
  final Future<void> Function(int lastWordIndex, double progress, Set<int> tappedWordIndices)? onProgressChanged;

  const ReaderView({
    super.key,
    required this.text,
    this.initialWordIndex = 0,
    this.initialTappedWordIndices = const {},
    this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReaderCubit(onProgressChanged: onProgressChanged),
      child: _ReaderContent(
        text: text,
        initialWordIndex: initialWordIndex,
        initialTappedWordIndices: initialTappedWordIndices,
      ),
    );
  }
}

class _ReaderContent extends StatelessWidget {
  final String text;
  final int initialWordIndex;
  final Set<int> initialTappedWordIndices;

  const _ReaderContent({
    required this.text,
    required this.initialWordIndex,
    required this.initialTappedWordIndices,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReaderCubit, ReaderState>(
      listener: (context, state) {
        if (state is ReaderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loaded = state is ReaderLoaded ? state : null;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            // Wait for the save to actually finish before leaving, so the
            // library list (read right after this route pops) sees it.
            await context.read<ReaderCubit>().saveProgress();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.text_fields, size: 18, color: AppColors.textSecondary),
                  Expanded(
                    child: Slider(
                      value: loaded?.fontSize ?? 16,
                      min: 12,
                      max: 28,
                      activeColor: AppColors.accent,
                      onChanged: loaded == null
                          ? null
                          : (value) => context.read<ReaderCubit>().changeFontSize(value),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  // This LayoutBuilder sits inside the padding, so its
                  // constraints ARE the Wrap's exact box - no estimated
                  // chrome heights anywhere.
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (state is ReaderInitial) {
                        final cubit = context.read<ReaderCubit>();
                        final textScaler = MediaQuery.textScalerOf(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (cubit.state is ReaderInitial) {
                            cubit.loadDocument(
                              text,
                              containerWidth: constraints.maxWidth,
                              containerHeight: constraints.maxHeight,
                              textScaler: textScaler,
                              initialWordIndex: initialWordIndex,
                              initialTappedWordIndices: initialTappedWordIndices,
                            );
                          }
                        });
                      }

                      return switch (state) {
                        ReaderInitial() || ReaderLoading() || ReaderError() =>
                          const Center(child: CircularProgressIndicator()),
                        ReaderLoaded() => _ReaderPage(state: state),
                      };
                    },
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.progressTrack)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.textPrimary,
                    onPressed: loaded != null && loaded.currentPageIndex > 0
                        ? () => context.read<ReaderCubit>().previousPage()
                        : null,
                  ),
                  Text(
                    loaded == null
                        ? '- / -'
                        : '${loaded.currentPageIndex + 1} / ${loaded.pages.length}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.textPrimary,
                    onPressed: loaded != null &&
                            loaded.currentPageIndex < loaded.pages.length - 1
                        ? () => context.read<ReaderCubit>().nextPage()
                        : null,
                  ),
                ],
              ),
            ),
            ],
          ),
        );
      },
    );
  }
}

class _ReaderPage extends StatelessWidget {
  final ReaderLoaded state;

  const _ReaderPage({required this.state});

  @override
  Widget build(BuildContext context) {
    final currentWords = state.pages[state.currentPageIndex];
    final startIndex = state.pages
        .take(state.currentPageIndex)
        .fold<int>(0, (sum, page) => sum + page.length);

    return Wrap(
      spacing: readerWordSpacing,
      runSpacing: readerRunSpacing,
      children: [
        for (var i = 0; i < currentWords.length; i++)
          if (currentWords[i] == paragraphBreak)
            const SizedBox(width: double.infinity, height: 0)
          else
            _WordWidget(
              word: currentWords[i],
              isTapped: state.tappedWordIndices.contains(startIndex + i),
              onTap: () => context.read<ReaderCubit>().toggleWord(startIndex + i),
              fontSize: state.fontSize,
            ),
      ],
    );
  }
}

class _WordWidget extends StatefulWidget {
  final String word;
  final bool isTapped;
  final VoidCallback onTap;
  final double fontSize;

  const _WordWidget({
    required this.word,
    required this.isTapped,
    required this.onTap,
    required this.fontSize,
  });

  @override
  State<_WordWidget> createState() => _WordWidgetState();
}

class _WordWidgetState extends State<_WordWidget> {
  String? _translation;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isTapped) _fetchTranslation();
  }

  @override
  void didUpdateWidget(covariant _WordWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTapped && _translation == null && !_loading) {
      _fetchTranslation();
    }
  }

  Future<void> _fetchTranslation() async {
    final cleaned = _stripPunctuation(widget.word);
    if (cleaned.isEmpty) {
      setState(() {
        _translation = '';
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final result = await _translateWord(cleaned);
    if (mounted) {
      setState(() {
        _translation = result;
        _loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.word,
            style: readerTextStyle(widget.fontSize, color: AppColors.textPrimary),
          ),
          Visibility(
            visible: widget.isTapped,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              _loading ? '...' : (_translation ?? ''),
              style: readerTextStyle(widget.fontSize * 0.7, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
