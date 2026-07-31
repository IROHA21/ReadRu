import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:read_ru/l10n/generated/app_localizations.dart';

// TRANSLATION - keyed by "source>target:word" so the same raw word doesn't
// collide across different book/spoken-language pairs.
final Map<String, String> _translationCache = {};

// Increments every time a translation actually falls through to Yandex
// (network/cloud) - _YandexIndicatorIcon listens for this to flash briefly
// each time, then fade back to dim. A plain bool doesn't work here: once
// Yandex is used once its value stays true, and ValueNotifier only notifies
// listeners when the value actually CHANGES - re-setting it to the same
// true on every subsequent word would silently stop notifying at all. An
// ever-incrementing counter always changes, so it always fires.
final ValueNotifier<int> yandexTranslationTick = ValueNotifier<int>(0);

// Shared connectivity tracking - a single OS-level subscription that both
// _YandexIndicatorIcon (for its offline icon state) and _translateOnDevice
// (to decide whether an "unchanged" ML Kit result is worth discarding, see
// below) read from, instead of each keeping its own separate listener.
final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);
bool _connectivityTrackingStarted = false;

void _ensureConnectivityTracking() {
  if (_connectivityTrackingStarted) return;
  _connectivityTrackingStarted = true;
  Connectivity().checkConnectivity().then((results) => isOffline.value = !results.hasConnectivity);
  Connectivity().onConnectivityChanged.listen((results) {
    isOffline.value = !results.hasConnectivity;
  });
}

// Strips leading/trailing punctuation - \p{L}/\p{N} match any letter/number
// in any script (Cyrillic included), so this doesn't assume Latin text.
String _stripPunctuation(String word) {
  return word.replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '');
}

// TEMPORARY DEBUG SWITCH - while true, a failed/empty/unchanged on-device
// result shows directly as "(ml kit failed)" instead of silently falling
// back to Yandex, so ML Kit's own behavior is visible instead of being
// masked. Left false now that ML Kit has been confirmed working; flip back
// to true only to isolate ML Kit again for debugging.
const bool _debugDisableYandexFallback = false;

// TEMPORARY DEBUG SWITCH - while true, skips the on-device attempt entirely
// so every translation goes through Yandex, for testing the cloud indicator
// icon without needing a word ML Kit can't handle. Flip back to false
// before shipping.
const bool _debugForceYandex = false;

// ML Kit on-device translation first (silent, offline, free); Yandex is a
// fallback for whatever ML Kit doesn't handle well - a thrown error (model
// not downloaded, unsupported pair), an empty result, or a result that's
// just the input unchanged. An unchanged result can't be trusted on its own:
// it's indistinguishable from a real (undocumented) ML Kit failure mode
// where it silently echoes the input back for specific content with no
// error at all - see https://github.com/googlesamples/mlkit/issues/1051.
// No user-facing toggle between the two engines.
//
// [sourceLanguage] is null when the book's language isn't set or isn't one
// ML Kit/Yandex can translate - in that case there's nothing to try, so this
// says so directly instead of guessing.
Future<String> _translateWord(
  String word, {
  required TranslateLanguage? sourceLanguage,
  required TranslateLanguage? targetLanguage,
}) async {
  _ensureConnectivityTracking();
  if (sourceLanguage == null) {
    return translationUnsupportedMarker;
  }
  final target = targetLanguage ?? TranslateLanguage.english;

  // Same source and target language (e.g. an English book with English as
  // the spoken language) - the word is already "translated," and there's
  // nothing ML Kit or Yandex could usefully add. Skip both engines entirely
  // rather than treating the inevitable unchanged result as a failure and
  // burning a Yandex call on every single word in the book.
  if (sourceLanguage == target) return word;

  final cacheKey = '${sourceLanguage.bcpCode}>${target.bcpCode}:$word';
  final cached = _translationCache[cacheKey];
  if (cached != null) return cached;

  final onDevice =
      _debugForceYandex ? null : await _translateOnDevice(word, sourceLanguage, target);
  String result;
  if (onDevice != null) {
    result = onDevice;
  } else if (_debugDisableYandexFallback) {
    result = '(ml kit failed)';
  } else if (isOffline.value) {
    // No point attempting a network call that's guaranteed to fail (and,
    // if the connection is in a half-broken state rather than fully off,
    // could hang for a while before it does) - go straight to the same
    // failure result Yandex would eventually return anyway.
    result = translationFailedMarker;
  } else {
    yandexTranslationTick.value++;
    result = await _translateWithYandex(word, sourceLanguage.bcpCode, target.bcpCode);
  }

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

// The stored/cached translation value is always the canonical English
// sentinel (translationFailedMarker/translationUnsupportedMarker), so it
// stays comparable and correctly persisted regardless of locale - this
// only swaps in the localized text at the point of display.
String _displayTranslation(String raw, AppLocalizations l10n) {
  if (raw == translationFailedMarker) return l10n.translationFailed;
  if (raw == translationUnsupportedMarker) return l10n.translationUnsupported;
  return raw;
}

// ML Kit translation works fully offline, but its on-device models are
// weaker than Yandex's cloud translation - which needs internet and is
// unreachable when there's no connection. Warn once per book-open rather
// than staying silent about why translations might read worse than usual.
Future<void> _warnIfOffline(BuildContext context) async {
  final results = await Connectivity().checkConnectivity();
  if (results.hasConnectivity || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.offlineTranslationWarningTitle),
      content: Text(l10n.offlineTranslationWarning),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.close)),
      ],
    ),
  );
}

// Calls our own Cloud Function (cloud_functions/translate_proxy) instead of
// Yandex directly - the real Yandex API key/folder id live only in that
// function's environment variables now, never in the compiled app. The
// function passes Yandex's response straight through, so the parsing here
// is unchanged from the old direct-call version.
const String _translateProxyUrl = 'https://functions.yandexcloud.net/d4earbgeikkarhb5pj6r';

Future<String> _translateWithYandex(String word, String sourceCode, String targetCode) async {
  try {
    final response = await http.post(
      Uri.parse(_translateProxyUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-App-Secret': appSharedSecret,
      },
      body: jsonEncode({
        'word': word,
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

// Always visible at a dim baseline (so there's something to compare the
// flash against), and flashes to full accent color the instant Yandex is
// used, then eases back down to dim over a beat - a brief "light up," not a
// state that just stays on.
class _YandexIndicatorIcon extends StatefulWidget {
  const _YandexIndicatorIcon();

  @override
  State<_YandexIndicatorIcon> createState() => _YandexIndicatorIconState();
}

class _YandexIndicatorIconState extends State<_YandexIndicatorIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _lastTick;

  @override
  void initState() {
    super.initState();
    _lastTick = yandexTranslationTick.value;
    // Idle value is 0 (the controller's default lowerBound) so the icon
    // starts dim, not lit - only _onTick ever pushes it up.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    yandexTranslationTick.addListener(_onTick);
    _ensureConnectivityTracking();
    isOffline.addListener(_onOfflineChanged);
  }

  void _onOfflineChanged() {
    if (mounted) setState(() {});
  }

  void _onTick() {
    if (yandexTranslationTick.value == _lastTick) return;
    _lastTick = yandexTranslationTick.value;
    // Jump straight to fully lit (no animated fade-in - the flash should be
    // instant), then animate the decay back down to dim.
    _controller.value = 1;
    _controller.animateTo(0, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    yandexTranslationTick.removeListener(_onTick);
    isOffline.removeListener(_onOfflineChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Offline: Yandex can't be reached at all, so the pulse is moot - an
    // explicit red X stacked over the cloud says so directly instead of
    // showing a cloud that will never light up.
    if (isOffline.value) {
      return Tooltip(
        message: l10n.yandexOfflineTooltip,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.cloud, size: 18, color: colors.textSecondary.withValues(alpha: 0.5)),
            const Icon(Icons.close, size: 14, color: Colors.red),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final lit = _controller.value;
        return Tooltip(
          message: _controller.isAnimating ? l10n.yandexActiveTooltip : l10n.yandexInactiveTooltip,
          child: Icon(
            Icons.cloud,
            size: 18,
            color: Color.lerp(colors.textSecondary.withValues(alpha: 0.35), colors.accent, lit),
          ),
        );
      },
    );
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
    final l10n = AppLocalizations.of(context)!;
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
          // Pinned to LTR regardless of the app's interface language - the
          // reading area (word Wrap, page prev/counter/next bar) reflects
          // the book's own layout, not the app UI's locale. Reading
          // direction for the book itself is controlled by the explicit
          // "Page turn direction" setting, not by ambient Directionality;
          // letting Arabic-as-app-language flip this would reverse page
          // navigation and word order for every book, RTL script or not.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (chapters.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.menu_book, color: colors.textPrimary),
                      tooltip: l10n.chaptersTooltip,
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: _YandexIndicatorIcon(),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: colors.textPrimary),
                    tooltip: l10n.readingSettingsTooltip,
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
                            unawaited(_warnIfOffline(context));
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
                          ? l10n.pageCounterUnknown
                          : l10n.pageCounter(loaded.currentPageIndex + 1, loaded.pages.length),
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
    final l10n = AppLocalizations.of(context)!;
    final Color? background = widget.isSelected
        ? colors.accent.withValues(alpha: 0.35)
        : (widget.isTapped && widget.highlightEnabled
            ? widget.highlightColor.withValues(alpha: 0.55)
            : null);

    // Translations must never be wider than their word - pagination only
    // ever budgets room for the word itself (see measured_pagination.dart),
    // so a wider translation would push the rest of the Wrap onto later
    // rows than what was paginated for, and the page's fixed-height
    // ClipRect would clip the overflow instead of showing it. Capping the
    // translation to the word's measured width and letting FittedBox
    // shrink it to fit keeps every word's footprint exactly what
    // pagination expected.
    final wordPainter = TextPainter(
      text: TextSpan(text: widget.word, style: readerTextStyle(widget.fontSize, font: widget.font)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final wordWidth = wordPainter.width;
    wordPainter.dispose();

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
            child: SizedBox(
              width: wordWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _loading ? '...' : _displayTranslation(_translation ?? '', l10n),
                  maxLines: 1,
                  style: readerTextStyle(widget.translationFontSize, font: widget.font, color: widget.translationColor),
                ),
              ),
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
    final l10n = AppLocalizations.of(context)!;
    // Shown via showModalBottomSheet, which pushes onto the app's root
    // Navigator/Overlay rather than nesting under _ReaderContent's own
    // Directionality override - pin it separately so chapter titles and
    // page numbers (book content, not app chrome) don't flip under an
    // Arabic app language either.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                l10n.chapters,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            for (final chapter in chapters)
              ListTile(
                title: Text(chapter.title, style: TextStyle(color: colors.textPrimary)),
                trailing: Text(
                  l10n.chapterPageLabel(_pageIndexFor(chapter.wordIndex) + 1),
                  style: TextStyle(color: colors.textSecondary),
                ),
                onTap: () {
                  onSelected(chapter);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;

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
            tooltip: l10n.cancelSelectionTooltip,
            onPressed: cubit.clearSelection,
          ),
          Expanded(
            child: Text(
              l10n.wordsSelected(count),
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
            label: Text(l10n.translateButton, style: TextStyle(color: colors.accent)),
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
    final l10n = AppLocalizations.of(context)!;
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
                : Text(_displayTranslation(translation, l10n), style: TextStyle(fontSize: 16, color: colors.accent)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.close),
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
                    child: Text(_saved ? l10n.saved : l10n.saveToWordBucket),
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
