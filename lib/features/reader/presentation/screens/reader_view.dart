import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/config/secrets.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/core/widgets/page_turn_loader.dart';
import 'package:read_ru/features/library/domain/entities/chapter.dart';
import 'package:read_ru/features/onboarding/domain/supported_languages.dart';
import 'package:read_ru/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:read_ru/features/reader/domain/split_into_words.dart';
import 'package:read_ru/features/reader/presentation/cubit/reader_cubit.dart';
import 'package:read_ru/features/reader/presentation/cubit/reader_state.dart';
import 'package:read_ru/features/reader/presentation/layout/measured_pagination.dart';
import 'package:read_ru/features/settings/domain/reader_font.dart';
import 'package:read_ru/features/settings/domain/reader_settings.dart';
import 'package:read_ru/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:read_ru/features/settings/presentation/screens/settings_screen.dart';
import 'package:read_ru/features/word_bucket/domain/entities/word_bucket_entry.dart';
import 'package:read_ru/features/word_bucket/domain/repositories/word_bucket_repository.dart';

// TRANSLATION - keyed by "source>target:word" so the same raw word doesn't
// collide across different book/spoken-language pairs.
final Map<String, String> _translationCache = {};

// Strips leading/trailing punctuation - \p{L}/\p{N} match any letter/number
// in any script (Cyrillic included), so this doesn't assume Latin text.
String _stripPunctuation(String word) {
  return word.replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '');
}

// TEMPORARY DEBUG SWITCH - set back to false once ML Kit is confirmed
// working. While true, a failed/empty/unchanged on-device result shows
// directly as "(ml kit failed)" instead of silently falling back to
// Yandex, so ML Kit's own behavior is visible instead of being masked.
const bool _debugDisableYandexFallback = true;

// ML Kit on-device translation first (silent, offline, free); Yandex is a
// silent fallback for whatever ML Kit doesn't handle well - a thrown error
// (model not downloaded, unsupported pair), an empty result, or a result
// that's just the input unchanged. No user-facing toggle between the two.
//
// [sourceLanguage] is null when the book's language isn't set or isn't one
// ML Kit/Yandex can translate - in that case there's nothing to try, so this
// says so directly instead of guessing.
Future<String> _translateWord(
  String word, {
  required TranslateLanguage? sourceLanguage,
  required TranslateLanguage? targetLanguage,
}) async {
  if (sourceLanguage == null) {
    return translationUnsupportedMarker;
  }
  final target = targetLanguage ?? TranslateLanguage.english;

  final cacheKey = '${sourceLanguage.bcpCode}>${target.bcpCode}:$word';
  final cached = _translationCache[cacheKey];
  if (cached != null) return cached;

  final onDevice = await _translateOnDevice(word, sourceLanguage, target);
  final result = onDevice ??
      (_debugDisableYandexFallback
          ? '(ml kit failed)'
          : await _translateWithYandex(word, sourceLanguage.bcpCode, target.bcpCode));

  if (isUsableTranslation(result)) _translationCache[cacheKey] = result;
  return result;
}

// Returns null (not the fallback string) whenever the on-device result
// isn't usable, so the caller knows to fall through to Yandex.
Future<String?> _translateOnDevice(String word, TranslateLanguage source, TranslateLanguage target) async {
  final translator = OnDeviceTranslator(sourceLanguage: source, targetLanguage: target);
  try {
    final result = (await translator.translateText(word)).trim();
    if (result.isEmpty) return null;
    if (result.toLowerCase() == word.trim().toLowerCase()) return null;
    return result;
  } catch (_) {
    return null;
  } finally {
    unawaited(translator.close());
  }
}

Future<String> _translateWithYandex(String word, String sourceCode, String targetCode) async {
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
        'sourceLanguageCode': sourceCode,
        'targetLanguageCode': targetCode,
      }),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (decoded['translations'] as List).first['text'] as String;
  } catch (e) {
    return translationFailedMarker;
  }
}

class ReaderView extends StatelessWidget {
  final String text;
  final String documentId;
  final String documentTitle;
  // BCP-47 code (Document.language) - the language this book is written
  // in, i.e. the translation source. Null means untranslatable (see
  // translateLanguageFromCode).
  final String? documentLanguage;
  final List<Chapter> chapters;
  final int initialWordIndex;
  final Set<int> initialTappedWordIndices;
  final Map<int, String> initialTranslatedWords;
  final Future<void> Function(
    int lastWordIndex,
    double progress,
    Set<int> tappedWordIndices,
    Map<int, String> translatedWords,
  )? onProgressChanged;

  const ReaderView({
    super.key,
    required this.text,
    required this.documentId,
    required this.documentTitle,
    this.documentLanguage,
    this.chapters = const [],
    this.initialWordIndex = 0,
    this.initialTappedWordIndices = const {},
    this.initialTranslatedWords = const {},
    this.onProgressChanged,
  });

  void _onWordTranslated(String word, String translation) {
    if (!isUsableTranslation(translation)) return;
    getIt<WordBucketRepository>().addEntry(WordBucketEntry(
      word: word,
      translation: translation,
      documentId: documentId,
      documentTitle: documentTitle,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReaderCubit(onProgressChanged: onProgressChanged),
      child: _ReaderContent(
        text: text,
        sourceLanguage: translateLanguageFromCode(documentLanguage),
        chapters: chapters,
        initialWordIndex: initialWordIndex,
        initialTappedWordIndices: initialTappedWordIndices,
        initialTranslatedWords: initialTranslatedWords,
        onWordTranslated: _onWordTranslated,
      ),
    );
  }
}

class _ReaderContent extends StatelessWidget {
  final String text;
  final TranslateLanguage? sourceLanguage;
  final List<Chapter> chapters;
  final int initialWordIndex;
  final Set<int> initialTappedWordIndices;
  final Map<int, String> initialTranslatedWords;
  final void Function(String word, String translation) onWordTranslated;

  const _ReaderContent({
    required this.text,
    required this.sourceLanguage,
    required this.chapters,
    required this.initialWordIndex,
    required this.initialTappedWordIndices,
    required this.initialTranslatedWords,
    required this.onWordTranslated,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final settings = context.watch<SettingsCubit>().state;

    return BlocListener<SettingsCubit, ReaderSettings>(
      listenWhen: (previous, current) =>
          previous.fontSize != current.fontSize ||
          previous.font != current.font ||
          previous.translationFontSize != current.translationFontSize,
      listener: (context, settings) {
        final cubit = context.read<ReaderCubit>();
        if (cubit.state is ReaderLoaded) {
          cubit.applySettings(
            fontSize: settings.fontSize,
            font: settings.font,
            translationFontSize: settings.translationFontSize,
          );
        }
      },
      child: BlocConsumer<ReaderCubit, ReaderState>(
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (chapters.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.menu_book, color: colors.textPrimary),
                      tooltip: 'Chapters',
                      onPressed: loaded == null
                          ? null
                          : () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => _ChapterListSheet(
                                  chapters: chapters,
                                  pages: loaded.pages,
                                  onSelected: (chapter) =>
                                      context.read<ReaderCubit>().jumpToWordIndex(chapter.wordIndex),
                                ),
                              ),
                    ),
                  Expanded(
                    child: Builder(builder: (context) {
                      final currentChapter =
                          loaded == null ? null : _currentChapter(chapters, loaded);
                      if (currentChapter == null) return const SizedBox.shrink();
                      return Text(
                        currentChapter.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      );
                    }),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: colors.textPrimary),
                    tooltip: 'Reading settings',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  if (loaded == null || loaded.isSelecting) return;
                  const minVelocity = 200.0;
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < minVelocity) return;

                  // velocity < 0 means the finger moved right-to-left (a
                  // "swipe left"); > 0 means left-to-right ("swipe right").
                  final swipedLeft = velocity < 0;
                  final reversed = settings.pageSwipeDirection == PageSwipeDirection.rightToLeft;
                  final goToNext = reversed ? !swipedLeft : swipedLeft;

                  final cubit = context.read<ReaderCubit>();
                  if (goToNext) {
                    cubit.nextPage();
                  } else {
                    cubit.previousPage();
                  }
                },
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
                              fontSize: settings.fontSize,
                              font: settings.font,
                              translationFontSize: settings.translationFontSize,
                              initialWordIndex: initialWordIndex,
                              initialTappedWordIndices: initialTappedWordIndices,
                              initialTranslatedWords: initialTranslatedWords,
                              chapters: chapters,
                            );
                          }
                        });
                      }

                      return switch (state) {
                        ReaderInitial() || ReaderLoading() || ReaderError() =>
                          const Center(child: PageTurnLoader()),
                        ReaderLoaded() => _ReaderPage(
                            state: state,
                            settings: settings,
                            sourceLanguage: sourceLanguage,
                            onWordTranslated: onWordTranslated,
                          ),
                      };
                    },
                    ),
                  ),
                ),
              ),
            ),
            if (loaded != null && loaded.isSelecting)
              _SelectionToolbar(colors: colors, sourceLanguage: sourceLanguage, onWordTranslated: onWordTranslated)
            else
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border(top: BorderSide(color: colors.progressTrack)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      color: colors.textPrimary,
                      onPressed: loaded != null && loaded.currentPageIndex > 0
                          ? () => context.read<ReaderCubit>().previousPage()
                          : null,
                    ),
                    Text(
                      loaded == null
                          ? '- / -'
                          : '${loaded.currentPageIndex + 1} / ${loaded.pages.length}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      color: colors.textPrimary,
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
      ),
    );
  }
}

// The chapter the reader is currently inside of - the last one (in document
// order) whose wordIndex is at or before the current page's first word.
// Null before the first chapter heading (e.g. a preface) or when there are
// no chapters at all.
Chapter? _currentChapter(List<Chapter> chapters, ReaderLoaded state) {
  if (chapters.isEmpty) return null;

  final startIndex = state.pages
      .take(state.currentPageIndex)
      .fold<int>(0, (sum, page) => sum + page.length);

  Chapter? current;
  for (final chapter in chapters) {
    if (chapter.wordIndex > startIndex) break;
    current = chapter;
  }
  return current;
}

class _ReaderPage extends StatelessWidget {
  final ReaderLoaded state;
  final ReaderSettings settings;
  final TranslateLanguage? sourceLanguage;
  final void Function(String word, String translation) onWordTranslated;

  const _ReaderPage({
    required this.state,
    required this.settings,
    required this.sourceLanguage,
    required this.onWordTranslated,
  });

  bool _inSelection(int wordIndex) {
    final anchor = state.selectionAnchor;
    final focus = state.selectionFocus;
    if (anchor == null || focus == null) return false;
    final start = anchor < focus ? anchor : focus;
    final end = anchor < focus ? focus : anchor;
    return wordIndex >= start && wordIndex <= end;
  }

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
              sourceLanguage: sourceLanguage,
              isTapped: state.tappedWordIndices.contains(startIndex + i),
              isSelected: _inSelection(startIndex + i),
              cachedTranslation: state.translatedWords[startIndex + i],
              onTap: () {
                final cubit = context.read<ReaderCubit>();
                if (state.isSelecting) {
                  cubit.extendSelection(startIndex + i);
                } else {
                  cubit.toggleWord(startIndex + i);
                }
              },
              onLongPress: () => context.read<ReaderCubit>().startSelection(startIndex + i),
              onTranslated: (translation) {
                context.read<ReaderCubit>().setTranslation(startIndex + i, translation);
                onWordTranslated(currentWords[i], translation);
              },
              fontSize: state.fontSize,
              font: state.font,
              translationFontSize: state.translationFontSize,
              highlightEnabled: settings.highlightEnabled,
              highlightColor: settings.highlightColor,
              translationColor: settings.translationColor,
            ),
      ],
    );
  }
}

class _WordWidget extends StatefulWidget {
  final String word;
  final TranslateLanguage? sourceLanguage;
  final bool isTapped;
  // Part of an in-progress phrase selection (long-press mode) - takes
  // visual precedence over the tap-to-translate highlight.
  final bool isSelected;
  // Translation already known for this exact word occurrence (persisted
  // per-document by index) - when set, skips the API call entirely.
  final String? cachedTranslation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double fontSize;
  final ReaderFont font;
  final double translationFontSize;
  final bool highlightEnabled;
  final Color highlightColor;
  final Color translationColor;
  final void Function(String translation) onTranslated;

  const _WordWidget({
    required this.word,
    required this.sourceLanguage,
    required this.isTapped,
    required this.isSelected,
    required this.cachedTranslation,
    required this.onTap,
    required this.onLongPress,
    required this.fontSize,
    required this.font,
    required this.translationFontSize,
    required this.highlightEnabled,
    required this.highlightColor,
    required this.translationColor,
    required this.onTranslated,
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
    if (widget.cachedTranslation != null) {
      _translation = widget.cachedTranslation;
    } else if (widget.isTapped) {
      _fetchTranslation();
    }
  }

  @override
  void didUpdateWidget(covariant _WordWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cachedTranslation != null && _translation == null) {
      setState(() => _translation = widget.cachedTranslation);
    } else if (widget.isTapped && _translation == null && !_loading) {
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
    final targetLanguage = context.read<OnboardingCubit>().state.spokenLanguage;
    final result = await _translateWord(
      cleaned,
      sourceLanguage: widget.sourceLanguage,
      targetLanguage: targetLanguage,
    );
    if (mounted) {
      setState(() {
        _translation = result;
        _loading = false;
      });
    }
    widget.onTranslated(result);
  }


  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final Color? background = widget.isSelected
        ? colors.accent.withValues(alpha: 0.35)
        : (widget.isTapped && widget.highlightEnabled
            ? widget.highlightColor.withValues(alpha: 0.55)
            : null);
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.word,
            style: readerTextStyle(widget.fontSize, font: widget.font, color: colors.textPrimary).copyWith(
              backgroundColor: background,
            ),
          ),
          Visibility(
            visible: widget.isTapped,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              _loading ? '...' : (_translation ?? ''),
              style: readerTextStyle(widget.translationFontSize, font: widget.font, color: widget.translationColor),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet listing the book's chapters/sections (only shown when the
// format's extractor actually found some - see ReaderView.chapters).
// Tapping one jumps the reader there and closes the sheet.
class _ChapterListSheet extends StatelessWidget {
  final List<Chapter> chapters;
  final List<List<String>> pages;
  final void Function(Chapter chapter) onSelected;

  const _ChapterListSheet({required this.chapters, required this.pages, required this.onSelected});

  // Same "which page holds this word index" scan ReaderCubit does
  // internally - reader_view.dart doesn't have access to that private
  // method, and this list is small enough that a plain loop is fine.
  int _pageIndexFor(int wordIndex) {
    var cumulative = 0;
    for (var i = 0; i < pages.length; i++) {
      cumulative += pages[i].length;
      if (wordIndex < cumulative) return i;
    }
    return pages.isEmpty ? 0 : pages.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Chapters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
          ),
          for (final chapter in chapters)
            ListTile(
              title: Text(chapter.title, style: TextStyle(color: colors.textPrimary)),
              trailing: Text(
                'p. ${_pageIndexFor(chapter.wordIndex) + 1}',
                style: TextStyle(color: colors.textSecondary),
              ),
              onTap: () {
                onSelected(chapter);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

// Replaces the normal prev/count/next bar while a phrase is being selected
// (long-press-and-extend) - shows how much is selected and offers to
// translate it or back out of selection mode entirely.
class _SelectionToolbar extends StatelessWidget {
  final AppColors colors;
  final TranslateLanguage? sourceLanguage;
  final void Function(String word, String translation) onWordTranslated;

  const _SelectionToolbar({required this.colors, required this.sourceLanguage, required this.onWordTranslated});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final count = cubit.selectedWordCount;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.progressTrack)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary),
            tooltip: 'Cancel selection',
            onPressed: cubit.clearSelection,
          ),
          Expanded(
            child: Text(
              count == 1 ? '1 word selected' : '$count words selected',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton.icon(
            onPressed: count == 0
                ? null
                : () {
                    final phrase = cubit.selectedPhraseText();
                    if (phrase == null) return;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _PhraseTranslationSheet(
                        phrase: phrase,
                        sourceLanguage: sourceLanguage,
                        onSaved: onWordTranslated,
                      ),
                    );
                  },
            icon: Icon(Icons.translate, color: colors.accent),
            label: Text('Translate', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }
}

// Fetches and shows the translation of a multi-word selection. Unlike
// single tapped words, phrases keep their punctuation (no _stripPunctuation)
// since that matters for phrase-level machine translation.
class _PhraseTranslationSheet extends StatefulWidget {
  final String phrase;
  final TranslateLanguage? sourceLanguage;
  final void Function(String word, String translation) onSaved;

  const _PhraseTranslationSheet({required this.phrase, required this.sourceLanguage, required this.onSaved});

  @override
  State<_PhraseTranslationSheet> createState() => _PhraseTranslationSheetState();
}

class _PhraseTranslationSheetState extends State<_PhraseTranslationSheet> {
  String? _translation;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _translate();
  }

  Future<void> _translate() async {
    final targetLanguage = context.read<OnboardingCubit>().state.spokenLanguage;
    final result = await _translateWord(
      widget.phrase,
      sourceLanguage: widget.sourceLanguage,
      targetLanguage: targetLanguage,
    );
    if (mounted) setState(() => _translation = result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final translation = _translation;
    final canSave = translation != null && isUsableTranslation(translation) && !_saved;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.phrase,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
            const SizedBox(height: 12),
            translation == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Text(translation, style: TextStyle(fontSize: 16, color: colors.accent)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: !canSave
                        ? null
                        : () {
                            widget.onSaved(widget.phrase, translation);
                            setState(() => _saved = true);
                          },
                    child: Text(_saved ? 'Saved' : 'Save to Word Bucket'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
