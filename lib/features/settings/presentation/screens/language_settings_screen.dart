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

// App/goal language (same choices onboarding asked for, now editable) and
// offline pack management - every supported language, searchable, with
// download/delete per pack. The ones currently selected as app or goal
// language are starred.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final onboardingCubit = getIt<OnboardingCubit>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(l10n.languageFolderTitle),
      ),
      body: BlocBuilder<OnboardingCubit, OnboardingSettings>(
        bloc: onboardingCubit,
        builder: (context, settings) {
          final highlighted = <TranslateLanguage>{
            if (settings.spokenLanguage != null) settings.spokenLanguage!,
            ...settings.bookLanguages,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SectionLabel(l10n.appLanguageLabel, colors),
              Text(
                l10n.appLanguageDescription,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in popularSpokenLanguages)
                    ChoiceChip(
                      label: Text(translateLanguageName(language)),
                      selected: settings.spokenLanguage == language,
                      selectedColor: colors.accent.withValues(alpha: 0.25),
                      onSelected: (_) => onboardingCubit.setSpokenLanguage(language),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(l10n.goalLanguageLabel, colors),
              Text(
                l10n.goalLanguageDescription,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in settings.bookLanguages)
                    InputChip(
                      label: Text(translateLanguageName(language)),
                      onDeleted: () => onboardingCubit.toggleBookLanguage(language),
                    ),
                  ActionChip(
                    avatar: Icon(Icons.add, size: 18, color: colors.accent),
                    label: Text(l10n.addLanguageChip, style: TextStyle(color: colors.accent)),
                    onPressed: () async {
                      final selected = await showModalBottomSheet<TranslateLanguage>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _LanguageSearchSheet(
                          exclude: settings.bookLanguages.toSet(),
                        ),
                      );
                      if (selected != null) onboardingCubit.toggleBookLanguage(selected);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionLabel(l10n.offlinePacksLabel, colors),
              Text(
                l10n.offlinePacksDescription,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              LanguagePackManager(
                languages: allSupportedLanguages,
                highlighted: highlighted,
                showSearch: true,
                showDelete: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageSearchSheet extends StatefulWidget {
  final Set<TranslateLanguage> exclude;

  const _LanguageSearchSheet({required this.exclude});

  @override
  State<_LanguageSearchSheet> createState() => _LanguageSearchSheetState();
}

class _LanguageSearchSheetState extends State<_LanguageSearchSheet> {
  String _query = '';
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectable = allSupportedLanguages.where((l) => !widget.exclude.contains(l)).toList();
    final languages = visibleLanguages(all: selectable, query: _query, expanded: _expanded);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.addLanguageSheetTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  for (final language in languages)
                    ListTile(
                      title: Text(translateLanguageName(language), style: TextStyle(color: colors.textPrimary)),
                      onTap: () => Navigator.of(context).pop(language),
                    ),
                  if (_query.isEmpty && !_expanded && languages.length < selectable.length)
                    ListTile(
                      leading: Icon(Icons.expand_more, color: colors.accent),
                      title: Text(l10n.showMoreLanguages, style: TextStyle(color: colors.accent)),
                      onTap: () => setState(() => _expanded = true),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _SectionLabel(this.label, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
      ),
    );
  }
}
