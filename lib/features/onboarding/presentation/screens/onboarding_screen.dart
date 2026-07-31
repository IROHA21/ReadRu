import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/onboarding/domain/onboarding_settings.dart';
import 'package:read_ru/features/onboarding/domain/supported_languages.dart';
import 'package:read_ru/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:read_ru/features/onboarding/presentation/widgets/language_pack_manager.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

/// The 3-screen first-run flow: spoken language, book/learning language(s),
/// then permission to download the on-device translation models for them.
/// One shared cubit across all 3 steps, paged with a PageController instead
/// of pushed routes so "back" just pages back within the flow.
class OnboardingScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    // .value, not create: OnboardingCubit is a shared app-wide singleton
    // (main.dart's MaterialApp.locale is driven by this same instance) -
    // create: would make this provider own it and close() it the moment
    // this screen unmounts (right when onboarding completes and main.dart
    // swaps home: to LibraryListScreen), permanently killing the cubit
    // every language-setting screen after onboarding depends on.
    return BlocProvider.value(
      value: getIt<OnboardingCubit>(),
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
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OnboardingCubit, OnboardingSettings>(
      builder: (context, settings) {
        return _StepScaffold(
          title: l10n.spokenLanguageStepTitle,
          subtitle: l10n.spokenLanguageStepSubtitle,
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
            child: Text(l10n.continueButton),
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
  bool _expanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languages = visibleLanguages(all: allSupportedLanguages, query: _query, expanded: _expanded);

    return BlocBuilder<OnboardingCubit, OnboardingSettings>(
      builder: (context, settings) {
        return _StepScaffold(
          title: l10n.bookLanguageStepTitle,
          subtitle: l10n.bookLanguageStepSubtitle,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.searchLanguages,
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
                    if (_query.isEmpty && !_expanded && languages.length < allSupportedLanguages.length)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.expand_more, color: colors.accent),
                        title: Text(l10n.showMoreLanguages, style: TextStyle(color: colors.accent)),
                        onTap: () => setState(() => _expanded = true),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomBar: Row(
            children: [
              OutlinedButton(onPressed: widget.onBack, child: Text(l10n.back)),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: settings.bookLanguages.isEmpty ? null : widget.onNext,
                  child: Text(l10n.continueButton),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadModelsStep extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onBack;

  const _DownloadModelsStep({required this.onDone, required this.onBack});

  @override
  State<_DownloadModelsStep> createState() => _DownloadModelsStepState();
}

class _DownloadModelsStepState extends State<_DownloadModelsStep> {
  final _managerKey = GlobalKey<LanguagePackManagerState>();
  bool _downloading = false;
  // Set once a download attempt has finished - the button then reads
  // "Continue" instead of silently completing onboarding, so a failed
  // download (shown as "Download failed" with the real error under it,
  // right there in the list) is something the user actually sees before
  // moving on, not something that happens invisibly behind a page change.
  bool _downloaded = false;

  List<TranslateLanguage> _languagesFor(OnboardingSettings settings) {
    final languages = <TranslateLanguage>{
      if (settings.spokenLanguage != null) settings.spokenLanguage!,
      ...settings.bookLanguages,
    };
    return languages.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OnboardingCubit, OnboardingSettings>(
      builder: (context, settings) {
        final languages = _languagesFor(settings);
        // Never require more than there are to give - if onboarding only
        // offered 1 language total (e.g. spoken and book language are the
        // same), completing it can't be blocked on a threshold it's
        // impossible to reach.
        final requiredReady = languages.length < 2 ? languages.length : 2;
        final readyCount = _managerKey.currentState?.readyCount ?? 0;
        final canContinue = readyCount >= requiredReady;

        return _StepScaffold(
          title: l10n.downloadStepTitle,
          subtitle: l10n.downloadStepSubtitle,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LanguagePackManager(
              key: _managerKey,
              languages: languages,
              onChanged: () => setState(() {}),
            ),
          ),
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_downloaded && !canContinue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.downloadMinimumRequired(requiredReady),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  OutlinedButton(onPressed: widget.onBack, child: Text(l10n.back)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _downloading
                          ? null
                          : _downloaded
                              ? (canContinue
                                  ? () async {
                                      await context.read<OnboardingCubit>().completeOnboarding();
                                      widget.onDone();
                                    }
                                  : null)
                              : () async {
                                  setState(() => _downloading = true);
                                  await _managerKey.currentState?.downloadMissing();
                                  if (!mounted) return;
                                  setState(() {
                                    _downloading = false;
                                    _downloaded = true;
                                  });
                                },
                      child: Text(
                        _downloading
                            ? l10n.downloading
                            : _downloaded
                                ? l10n.continueButton
                                : l10n.download,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
