import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/onboarding/domain/onboarding_settings.dart';
import 'package:read_ru/features/onboarding/domain/supported_languages.dart';
import 'package:read_ru/features/onboarding/presentation/cubit/onboarding_cubit.dart';

/// The 3-screen first-run flow: spoken language, book/learning language(s),
/// then permission to download the on-device translation models for them.
/// One shared cubit across all 3 steps, paged with a PageController instead
/// of pushed routes so "back" just pages back within the flow.
class OnboardingScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>(),
      child: _OnboardingFlow(onComplete: onComplete),
    );
  }
}

class _OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const _OnboardingFlow({required this.onComplete});

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  final _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? colors.accent : colors.progressTrack,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SpokenLanguageStep(onNext: () => _goTo(1)),
                  _BookLanguageStep(onNext: () => _goTo(2), onBack: () => _goTo(0)),
                  _DownloadModelsStep(onDone: widget.onComplete, onBack: () => _goTo(1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final Widget bottomBar;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(subtitle, style: TextStyle(color: colors.textSecondary)),
        ),
        Expanded(child: body),
        Padding(
          padding: const EdgeInsets.all(20),
          child: bottomBar,
        ),
      ],
    );
  }
}

class _SpokenLanguageStep extends StatelessWidget {
  final VoidCallback onNext;

  const _SpokenLanguageStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return BlocBuilder<OnboardingCubit, OnboardingSettings>(
      builder: (context, settings) {
        return _StepScaffold(
          title: 'What language do you speak?',
          subtitle: "We'll translate books into this language.",
          body: RadioGroup<TranslateLanguage>(
            groupValue: settings.spokenLanguage,
            onChanged: (value) {
              if (value != null) context.read<OnboardingCubit>().setSpokenLanguage(value);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final language in popularSpokenLanguages)
                  RadioListTile<TranslateLanguage>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(translateLanguageName(language), style: TextStyle(color: colors.textPrimary)),
                    value: language,
                    activeColor: colors.accent,
                  ),
              ],
            ),
          ),
          bottomBar: FilledButton(
            onPressed: settings.spokenLanguage == null ? null : onNext,
            child: const Text('Continue'),
          ),
        );
      },
    );
  }
}

class _BookLanguageStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _BookLanguageStep({required this.onNext, required this.onBack});

  @override
  State<_BookLanguageStep> createState() => _BookLanguageStepState();
}

class _BookLanguageStepState extends State<_BookLanguageStep> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final languages = allSupportedLanguages
        .where((l) => translateLanguageName(l).toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return BlocBuilder<OnboardingCubit, OnboardingSettings>(
      builder: (context, settings) {
        return _StepScaffold(
          title: 'What languages are your books in?',
          subtitle: 'Pick every language you read in - you can change this per book later.',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search languages',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final language in languages)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(translateLanguageName(language), style: TextStyle(color: colors.textPrimary)),
                        value: settings.bookLanguages.contains(language),
                        activeColor: colors.accent,
                        onChanged: (_) => context.read<OnboardingCubit>().toggleBookLanguage(language),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomBar: Row(
            children: [
              OutlinedButton(onPressed: widget.onBack, child: const Text('Back')),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: settings.bookLanguages.isEmpty ? null : widget.onNext,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _DownloadState { pending, downloading, done, failed }

// ML Kit's model manager doesn't report a real size or byte-level progress
// for a download - this is Google's own published ballpark for an
// on-device translation language model, not something we can query per
// language. Shown as an estimate everywhere, never as an exact figure.
// https://developers.google.com/ml-kit/language/translation
const int _estimatedModelSizeMb = 30;

class _DownloadModelsStep extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onBack;

  const _DownloadModelsStep({required this.onDone, required this.onBack});

  @override
  State<_DownloadModelsStep> createState() => _DownloadModelsStepState();
}

class _DownloadModelsStepState extends State<_DownloadModelsStep> {
  final _modelManager = OnDeviceTranslatorModelManager();
  final Map<TranslateLanguage, _DownloadState> _status = {};
  bool _downloading = false;

  List<TranslateLanguage> _languagesFor(OnboardingSettings settings) {
    final languages = <TranslateLanguage>{
      if (settings.spokenLanguage != null) settings.spokenLanguage!,
      ...settings.bookLanguages,
    };
    return languages.toList();
  }

  Future<void> _downloadOne(TranslateLanguage language) async {
    setState(() => _status[language] = _DownloadState.downloading);
    try {
      await _modelManager.downloadModel(language.bcpCode, isWifiRequired: false);
      setState(() => _status[language] = _DownloadState.done);
    } catch (_) {
      setState(() => _status[language] = _DownloadState.failed);
    }
  }

  Future<void> _downloadAll(List<TranslateLanguage> languages) async {
    setState(() => _downloading = true);
    for (final language in languages) {
      await _downloadOne(language);
    }
    setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return BlocBuilder<OnboardingCubit, OnboardingSettings>(
      builder: (context, settings) {
        final languages = _languagesFor(settings);
        final doneCount = languages.where((l) => _status[l] == _DownloadState.done).length;
        final totalMb = languages.length * _estimatedModelSizeMb;

        return _StepScaffold(
          title: 'Download offline translation',
          subtitle:
              'Download these language packs so translation works fully offline afterward. You can skip this and do it later in Settings.',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$doneCount of ${languages.length} downloaded · ~$totalMb MB total',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: languages.isEmpty ? 0 : doneCount / languages.length,
                        minHeight: 6,
                        backgroundColor: colors.progressTrack,
                        valueColor: AlwaysStoppedAnimation(colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final language in languages)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: _status[language] == _DownloadState.failed
                            ? () => _downloadOne(language)
                            : null,
                        title: Text(translateLanguageName(language), style: TextStyle(color: colors.textPrimary)),
                        subtitle: switch (_status[language] ?? _DownloadState.pending) {
                          _DownloadState.downloading => Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  backgroundColor: colors.progressTrack,
                                  valueColor: AlwaysStoppedAnimation(colors.accent),
                                ),
                              ),
                            ),
                          _DownloadState.done => Text('Downloaded', style: TextStyle(color: colors.textSecondary)),
                          _DownloadState.failed =>
                            Text('Download failed - tap to retry', style: TextStyle(color: Colors.red.shade400)),
                          _DownloadState.pending =>
                            Text('~$_estimatedModelSizeMb MB', style: TextStyle(color: colors.textSecondary)),
                        },
                        trailing: switch (_status[language]) {
                          _DownloadState.done => Icon(Icons.check_circle, color: colors.accent),
                          _DownloadState.failed => const Icon(Icons.error_outline, color: Colors.red),
                          _ => null,
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomBar: Row(
            children: [
              OutlinedButton(onPressed: widget.onBack, child: const Text('Back')),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _downloading
                      ? null
                      : () => context.read<OnboardingCubit>().completeOnboarding().then((_) => widget.onDone()),
                  child: const Text('Skip for now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _downloading
                      ? null
                      : () async {
                          await _downloadAll(languages);
                          if (!context.mounted) return;
                          await context.read<OnboardingCubit>().completeOnboarding();
                          widget.onDone();
                        },
                  child: Text(_downloading ? 'Downloading...' : 'Download'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
